import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track_follow_state.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/utils/geo_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class TrackFollowNotifier extends Notifier<TrackFollowState> {
  StreamSubscription? _locationSub;

  // Història de distàncies per detectar tendència
  final List<double> _lastDistances = [];

  // Control de temps fora del track
  DateTime? _offTrackStart;

  static const double nearThreshold = 20; // torna al track
  static const double farThreshold = 35; // possible desviació
  static const int trendWindow = 6; // últims punts
  static const Duration offTrackDelay = Duration(seconds: 5);

  // Avisos offtrack
  DateTime? _lastOffTrackAlert;
  Duration offTrackCooldown = const Duration(seconds: 20);
  bool _offTrackDismissed = false;

  final AudioPlayer _player = AudioPlayer();

  @override
  TrackFollowState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
    });

    return const TrackFollowState(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
      showOffTrackSnackbar: false,
      showBackOnTrackSnackbar: false,
    );
  }

  // ------------------------------------------------------------
  // API pública per la UI (cridades des del map_screen)
  // ------------------------------------------------------------

  /// L’usuari s’està allunyant segons la detecció del map_screen
  void onUserDriftingAway() {
    if (_offTrackDismissed) return; // L’usuari ha tancat el snackbar

    final now = DateTime.now();
    final canAlert =
        _lastOffTrackAlert == null ||
        now.difference(_lastOffTrackAlert!) > offTrackCooldown;

    if (canAlert) {
      HapticFeedback.heavyImpact();
      _playOffTrackSound();
      _lastOffTrackAlert = now;

      // Notifiquem la UI perquè mostri el snackbar
      state = state.copyWith(showOffTrackSnackbar: true);
    }
  }

  /// L’usuari ha tornat al track → reiniciem avisos
  void onUserBackOnTrack() {
    _offTrackDismissed = false;

    // Vibració suau
    HapticFeedback.lightImpact();

    // So positiu
    _playBackOnTrackSound();

    // Notifiquem la UI
    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  /// La UI ha tancat el snackbar
  void dismissOffTrackAlert() {
    _offTrackDismissed = true;
  }

  // ------------------------------------------------------------
  // Seguiment del track importat
  // ------------------------------------------------------------

  void toggleFollowing(BuildContext context) {
    if (state.isFollowing) {
      stopFollowing();
    } else {
      startFollowingWithRecording(context);
    }
  }

  void startFollowingWithRecording(BuildContext context) async {
    state = state.copyWith(isFollowing: true);

    // 🔥 1. Obtenir última posició del track (GPS real)
    final track = ref.read(trackProvider);
    final imported = ref.read(importedTrackProvider);

    if (track.coordinates.isEmpty) {
      return;
    }

    if (imported == null || imported.coordinates.isEmpty) {
      return;
    }

    if (track.coordinates.isEmpty || imported.coordinates.isEmpty) return;

    final last = track.coordinates.last;
    final lastPos = LatLng(last[1], last[0]);

    // Convertim coordinates (List<List<double>>) → List<LatLng>
    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = _closestPointAndSegment(lastPos, importedLatLng);
    final dist = closest.distance;

    // 🔥 3. Decidir estat inicial
    final isNear = dist < nearThreshold;

    if (isNear) {
      // Està sobre el track → sonar OK
      HapticFeedback.lightImpact();
      _playBackOnTrackSound();
      state = state.copyWith(isOffTrack: false);
    } else {
      // Està fora → sonar alerta immediata
      HapticFeedback.mediumImpact();
      _playOffTrackSound();
      state = state.copyWith(isOffTrack: true);
    }

    // 🔥 4. Inicialitzar històric
    _lastDistances.clear();
    _lastDistances.add(dist);
  }

  void stopFollowing() {
    state = state.copyWith(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
      showOffTrackSnackbar: false,
    );

    _lastDistances.clear();
    _offTrackStart = null;
    _offTrackDismissed = false;
  }

  // ------------------------------------------------------------
  // Actualitzar posició de l’usuari
  // ------------------------------------------------------------
  void updateUserPosition(LatLng userPos) {
    if (!state.isFollowing) return;

    final imported = ref.read(importedTrackProvider);

    if (imported == null || imported.coordinates.isEmpty) return;

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = _closestPointAndSegment(userPos, importedLatLng);
    final dist = closest.distance;
    final trackBearing = closest.bearing;
    final userBearing = closest.userBearing;

    _lastDistances.add(dist);
    if (_lastDistances.length > trendWindow) {
      _lastDistances.removeAt(0);
    }

    final isTrendingAway = _isTrendingAway();
    final headingDiff = _headingDifference(trackBearing, userBearing);
    final isHeadingWrong = headingDiff > 45;

    final isFar = dist > farThreshold;
    final isNear = dist < nearThreshold;

    final wasOffTrack = state.isOffTrack;
    bool offTrack = state.isOffTrack;

    if (isFar && isTrendingAway && isHeadingWrong) {
      _offTrackStart ??= DateTime.now();

      if (DateTime.now().difference(_offTrackStart!) > offTrackDelay) {
        offTrack = true;
      }
    } else {
      _offTrackStart = null;
      if (isNear) offTrack = false;
    }

    // Vibració immediata quan entra en offtrack (però no snackbar)
    if (!wasOffTrack && offTrack) {
      HapticFeedback.mediumImpact();
    }

    // Reinici d’avisos quan torna al track
    if (wasOffTrack && !offTrack) {
      _offTrackDismissed = false;

      // 🔥 MILLORA NECESSÀRIA
      _offTrackStart = null;
      _lastDistances.clear();
      _lastDistances.add(dist);
    }

    state = state.copyWith(distanceToTrack: dist, isOffTrack: offTrack);
  }

  // ------------------------------------------------------------
  // Distància + bearing del segment més proper
  // ------------------------------------------------------------
  _ClosestResult _closestPointAndSegment(LatLng p, List<LatLng> track) {
    double minDist = double.infinity;
    double segmentBearing = 0;
    double userBearing = 0;

    for (int i = 0; i < track.length - 1; i++) {
      final a = track[i];
      final b = track[i + 1];

      // Vector AB
      final abx = b.longitude - a.longitude;
      final aby = b.latitude - a.latitude;

      // Vector AP
      final apx = p.longitude - a.longitude;
      final apy = p.latitude - a.latitude;

      // Projecció escalar de AP sobre AB
      final ab2 = abx * abx + aby * aby;
      double t = 0;
      if (ab2 > 0) {
        t = (apx * abx + apy * aby) / ab2;
      }

      // Clamp: si la projecció cau fora del segment, usem A o B
      t = t.clamp(0.0, 1.0);

      // Punt projectat sobre el segment
      final proj = LatLng(a.latitude + aby * t, a.longitude + abx * t);

      // Distància real punt–segment
      final d = distanceBetween(
        p.latitude,
        p.longitude,
        proj.latitude,
        proj.longitude,
      );

      if (d < minDist) {
        minDist = d;
        segmentBearing = bearingBetween(a, b);
        userBearing = bearingBetween(a, p);
      }
    }

    return _ClosestResult(
      distance: minDist,
      bearing: segmentBearing,
      userBearing: userBearing,
    );
  }

  // ------------------------------------------------------------
  // Tendència creixent
  // ------------------------------------------------------------
  bool _isTrendingAway() {
    if (_lastDistances.length < trendWindow) return false;

    for (int i = 1; i < _lastDistances.length; i++) {
      if (_lastDistances[i] < _lastDistances[i - 1]) {
        return false;
      }
    }
    return true;
  }

  // ------------------------------------------------------------
  // Diferència de heading (0–180)
  // ------------------------------------------------------------
  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  // ------------------------------------------------------------
  // REPRODUIR SO
  // ------------------------------------------------------------
  Future<void> _playOffTrackSound() async {
    try {
      await _player.play(AssetSource('sound/off_track.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint("Error playing off-track sound: $e");
    }
  }

  Future<void> _playBackOnTrackSound() async {
    try {
      await _player.play(AssetSource('sound/back_on_track.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint("Error playing back-on-track sound: $e");
    }
  }
}

class _ClosestResult {
  final double distance;
  final double bearing;
  final double userBearing;

  _ClosestResult({
    required this.distance,
    required this.bearing,
    required this.userBearing,
  });
}

final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
