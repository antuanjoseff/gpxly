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

enum FollowMode { notFollowing, initializing, onTrack, offTrack }

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
  int maxOffTrackAlerts = 1; // quantes vegades avisar
  Duration offTrackCooldown = Duration(seconds: 20); // temps entre avisos
  int offTrackAlertsSent = 0; // comptador

  DateTime? _lastOffTrackAlert;
  bool _offTrackDismissed = false;

  // Flags d’autòmat
  bool _isCurrentlyOffTrack = false; // Per saber si venim d'estar fora
  bool _backOnTrackAlertSent = false; // Per no repetir l'avís de "tornada"

  bool _hasEverBeenOnTrack = false;
  bool _hasEverBeenOffTrack = false;
  bool _hasShownBackOnTrackOnce = false;

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
      mode: FollowMode.notFollowing,
    );
  }

  // ------------------------------------------------------------
  // API pública per la UI
  // ------------------------------------------------------------

  void onUserDriftingAway() {
    if (_offTrackDismissed) return;

    final now = DateTime.now();
    final canAlert =
        _lastOffTrackAlert == null ||
        now.difference(_lastOffTrackAlert!) > offTrackCooldown;

    if (canAlert) {
      HapticFeedback.heavyImpact();
      _playOffTrackSound();
      _lastOffTrackAlert = now;

      state = state.copyWith(showOffTrackSnackbar: true);
    }
  }

  void onUserBackOnTrack() {
    _offTrackDismissed = false;

    HapticFeedback.lightImpact();
    _playBackOnTrackSound();

    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  void dismissOffTrackAlert() {
    _offTrackDismissed = true;
  }

  void clearOffTrackSnackbar() {
    state = state.copyWith(showOffTrackSnackbar: false);
  }

  void dismissBackOnTrackAlert() {
    state = state.copyWith(showBackOnTrackSnackbar: false);
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
    state = state.copyWith(isFollowing: true, mode: FollowMode.initializing);

    // Reiniciem flags
    _hasEverBeenOnTrack = false;
    _hasEverBeenOffTrack = false;
    offTrackAlertsSent = 0;

    // Obtenir última posició
    final track = ref.read(trackProvider);
    final imported = ref.read(importedTrackProvider);

    if (track.coordinates.isEmpty) return;
    if (imported == null || imported.coordinates.isEmpty) return;

    final last = track.coordinates.last;
    final lastPos = LatLng(last[1], last[0]);

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = _closestPointAndSegment(lastPos, importedLatLng);
    final dist = closest.distance;

    // Inicialitzar històric
    _lastDistances.clear();
    _lastDistances.add(dist);
  }

  void stopFollowing() {
    state = state.copyWith(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
      showOffTrackSnackbar: false,
      mode: FollowMode.notFollowing,
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

    // Deleguem tota la lògica d’estats
    _handleFollowState(
      dist: dist,
      isNear: isNear,
      isFar: isFar,
      isTrendingAway: isTrendingAway,
      isHeadingWrong: isHeadingWrong,
    );

    state = state.copyWith(distanceToTrack: dist);
  }

  // ------------------------------------------------------------
  // AUTÒMAT D’ESTATS
  // ------------------------------------------------------------
  void _handleFollowState({
    required double dist,
    required bool isNear,
    required bool isFar,
    required bool isTrendingAway,
    required bool isHeadingWrong,
  }) {
    final prevMode = state.mode;
    var newMode = prevMode;
    var newIsOffTrack = state.isOffTrack;

    // --- 1) INITIALIZING → ON_TRACK ---
    if (prevMode == FollowMode.initializing) {
      if (isNear) {
        newMode = FollowMode.onTrack;
        newIsOffTrack = false;
        _hasEverBeenOnTrack = true;
      }
    }
    // --- 2) ON_TRACK → OFF_TRACK ---
    else if (prevMode == FollowMode.onTrack) {
      if (isFar && isTrendingAway && isHeadingWrong) {
        if (_hasEverBeenOnTrack && _canSendOffTrackAlert()) {
          onUserDriftingAway(); // avis negatiu
        }
        _hasEverBeenOffTrack = true;
        newMode = FollowMode.offTrack;
        newIsOffTrack = true;
      }
    }
    // --- 3) OFF_TRACK → ON_TRACK ---
    else if (prevMode == FollowMode.offTrack) {
      if (isNear) {
        newMode = FollowMode.onTrack;
        newIsOffTrack = false;
      }
    }

    // --- Apliquem el nou estat ---
    state = state.copyWith(mode: newMode, isOffTrack: newIsOffTrack);

    // --- 🔥 AVÍS ON_TRACK NOMÉS EN TRANSICIÓ ---
    final hasEnteredOnTrack =
        prevMode != FollowMode.onTrack && newMode == FollowMode.onTrack;

    if (hasEnteredOnTrack) {
      onUserBackOnTrack(); // avis positiu
    }
  }

  bool _canSendOffTrackAlert() {
    if (offTrackAlertsSent >= maxOffTrackAlerts) return false;

    final now = DateTime.now();
    if (_lastOffTrackAlert == null ||
        now.difference(_lastOffTrackAlert!) > offTrackCooldown) {
      _lastOffTrackAlert = now;
      offTrackAlertsSent++;
      return true;
    }

    return false;
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

      final abx = b.longitude - a.longitude;
      final aby = b.latitude - a.latitude;

      final apx = p.longitude - a.longitude;
      final apy = p.latitude - a.latitude;

      final ab2 = abx * abx + aby * aby;
      double t = 0;
      if (ab2 > 0) {
        t = (apx * abx + apy * aby) / ab2;
      }

      t = t.clamp(0.0, 1.0);

      final proj = LatLng(a.latitude + aby * t, a.longitude + abx * t);

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

  bool _isTrendingAway() {
    if (_lastDistances.length < trendWindow) return false;

    for (int i = 1; i < _lastDistances.length; i++) {
      if (_lastDistances[i] < _lastDistances[i - 1]) {
        return false;
      }
    }
    return true;
  }

  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }

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
