import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track_follow_state.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/utils/geo_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum FollowMode { notFollowing, initializing, onTrack, offTrack }

class TrackFollowNotifier extends Notifier<TrackFollowState> {
  StreamSubscription? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  // Història de distàncies per detectar tendència
  final List<double> _lastDistances = [];

  // Control de temps fora del track
  DateTime? _offTrackStart;

  static const double nearThreshold = 20; // torna al track
  static const double farThreshold = 35; // possible desviació
  static const int trendWindow = 6; // últims punts
  static const Duration offTrackDelay = Duration(seconds: 30);

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
  bool _reverseDetectionLocked = false;
  final AudioPlayer _player = AudioPlayer();
  final List<LatLng> _lastUserPositions = [];
  double _distanceProgressOnTrack = 0.0;
  LatLng? _lastProjectedPoint;
  bool _reverseDialogShown = false;
  bool _offTrackSnackbarShown = false;

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
      showEndOfTrackSnackbar: false,
      showReverseTrackDialog: false,
      mode: FollowMode.notFollowing,
    );
  }

  // ------------------------------------------------------------
  // API pública per la UI
  // ------------------------------------------------------------

  void reverseImportedTrack() {
    ref.read(importedTrackProvider.notifier).reverseTrack();

    _lastDistances.clear();
    _hasEverBeenOnTrack = false;
    _hasEverBeenOffTrack = false;
    _offTrackDismissed = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false; // 🔥 AFEGIT
    offTrackAlertsSent = 0;

    state = state.copyWith(
      mode: FollowMode.initializing,
      showReverseTrackDialog: false,
      isOffTrack: false,
      distanceToTrack: 0,
    );
  }

  void onUserDriftingAway() {
    if (_offTrackDismissed) return;

    if (_canSendOffTrackAlert()) {
      _lastOffTrackAlert = DateTime.now();
      offTrackAlertsSent++;

      HapticFeedback.heavyImpact();
      _playOffTrackSound();

      if (_offTrackSnackbarShown) return;

      _offTrackSnackbarShown = true;
      state = state.copyWith(showOffTrackSnackbar: true);
    }
  }

  void onUserBackOnTrack() {
    _offTrackDismissed = false;

    HapticFeedback.lightImpact();
    _playBackOnTrackSound();

    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  void _askUserToReverseTrack() {
    if (_reverseDialogShown) return;

    _reverseDialogShown = true;
    state = state.copyWith(showReverseTrackDialog: true);
  }

  void dismissReverseTrackDialog() {
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;

    state = state.copyWith(showReverseTrackDialog: false);
  }

  void dismissEndOfTrackAlert() {
    state = state.copyWith(showEndOfTrackSnackbar: false);
  }

  void dismissOffTrackAlert() {
    _offTrackDismissed = true;
  }

  void clearOffTrackSnackbar() {
    _offTrackSnackbarShown = false;
    state = state.copyWith(showOffTrackSnackbar: false);
  }

  void dismissBackOnTrackAlert() {
    state = state.copyWith(showBackOnTrackSnackbar: false);
  }

  bool _isReverseDirection(_ClosestResult c) {
    if (_lastUserPositions.length < 2) return false;

    final prev = _lastUserPositions[_lastUserPositions.length - 2];
    final curr = _lastUserPositions[_lastUserPositions.length - 1];

    final movement = distanceBetween(
      prev.latitude,
      prev.longitude,
      curr.latitude,
      curr.longitude,
    );

    if (movement < 3) return false;

    final movementBearing = bearingBetween(prev, curr);
    final diff = _headingDifference(c.bearing, movementBearing);
    return diff > 135;
  }

  void toggleFollowing(BuildContext context) {
    if (state.isFollowing) {
      stopFollowing();
    } else {
      startFollowingWithRecording();
    }
  }

  void startFollowingWithRecording() async {
    state = state.copyWith(isFollowing: true, mode: FollowMode.initializing);

    _gpsSub = NativeGpsChannel.locationStream.listen((data) {
      final double lat = data["lat"];
      final double lon = data["lon"];
      updateUserPosition(LatLng(lat, lon));
    });

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
    _gpsSub?.cancel();
    _gpsSub = null;

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
  // 1. Fora de la funció, defineix el mètode de suport
  bool _checkIfFinished(_ClosestResult closest, double totalPoints) {
    final bool isNearEnd = closest.distance < 15;
    final bool isLastSegment = closest.segmentIndex >= totalPoints - 2;
    const double minProgressRequired = 100.0;
    final bool hasMinimumProgress =
        _distanceProgressOnTrack >= minProgressRequired;

    return isNearEnd && isLastSegment && hasMinimumProgress;
  }

  void updateUserPosition(LatLng userPos) {
    _lastUserPositions.add(userPos);
    if (_lastUserPositions.length > 10) _lastUserPositions.removeAt(0);

    if (!state.isFollowing) return;

    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = _closestPointAndSegment(userPos, importedLatLng);
    final proj = closest.projectedPoint;

    if (_lastProjectedPoint != null) {
      final step = distanceBetween(
        _lastProjectedPoint!.latitude,
        _lastProjectedPoint!.longitude,
        proj.latitude,
        proj.longitude,
      );
      if (step > 0 && step < 50) {
        _distanceProgressOnTrack += step;
      }
    }
    _lastProjectedPoint = proj;

    if (_checkIfFinished(closest, imported.coordinates.length.toDouble())) {
      HapticFeedback.lightImpact();
      _playBackOnTrackSound();
      state = state.copyWith(showEndOfTrackSnackbar: true);
      stopFollowing();
      return;
    }

    // 🔥 reversed detection segura
    if (state.mode == FollowMode.onTrack &&
        !_reverseDialogShown &&
        !_reverseDetectionLocked &&
        _isReverseDirection(closest)) {
      _reverseDetectionLocked = true;
      _askUserToReverseTrack();
      return;
    }

    final dist = closest.distance;
    _lastDistances.add(dist);
    if (_lastDistances.length > trendWindow) _lastDistances.removeAt(0);

    _handleFollowState(
      dist: dist,
      isNear: dist < nearThreshold,
      isFar: dist > farThreshold,
      isTrendingAway: _isTrendingAway(),
      isHeadingWrong:
          _headingDifference(closest.bearing, closest.userBearing) > 45,
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

    // INITIALIZING → ON_TRACK
    if (prevMode == FollowMode.initializing) {
      if (isNear) {
        newMode = FollowMode.onTrack;
        newIsOffTrack = false;
        _isCurrentlyOffTrack = false;
        _hasEverBeenOnTrack = true;
      }
    }
    // ON_TRACK → OFF_TRACK
    else if (prevMode == FollowMode.onTrack) {
      if (isFar) {
        _offTrackStart ??= DateTime.now();
      } else {
        _offTrackStart = null;
      }

      final timeExceeded =
          _offTrackStart != null &&
          DateTime.now().difference(_offTrackStart!) > offTrackDelay;

      if (isFar && (isTrendingAway || isHeadingWrong || timeExceeded)) {
        if (!_isCurrentlyOffTrack) {
          _isCurrentlyOffTrack = true;
          _offTrackDismissed = false; // 🔥 REINICIAR AQUÍ

          if (_hasEverBeenOnTrack) {
            onUserDriftingAway();
          }
        }

        _hasEverBeenOffTrack = true;
        newMode = FollowMode.offTrack;
        newIsOffTrack = true;
      }
    }
    // OFF_TRACK → ON_TRACK
    else if (prevMode == FollowMode.offTrack) {
      if (isNear) {
        newMode = FollowMode.onTrack;
        _isCurrentlyOffTrack = false;
        newIsOffTrack = false;
      }
    }

    state = state.copyWith(mode: newMode, isOffTrack: newIsOffTrack);

    final hasEnteredOnTrack =
        prevMode != FollowMode.onTrack && newMode == FollowMode.onTrack;

    if (hasEnteredOnTrack) {
      onUserBackOnTrack();
    }
  }

  bool _canSendOffTrackAlert() {
    if (offTrackAlertsSent >= maxOffTrackAlerts) return false;

    final now = DateTime.now();
    return _lastOffTrackAlert == null ||
        now.difference(_lastOffTrackAlert!) > offTrackCooldown;
  }

  // ------------------------------------------------------------
  // Distància + bearing del segment més proper
  // ------------------------------------------------------------
  _ClosestResult _closestPointAndSegment(LatLng p, List<LatLng> track) {
    double minDist = double.infinity;
    double segmentBearing = 0;
    double userBearing = 0;
    int bestSegmentIndex = 0;
    double bestT = 0;

    LatLng? bestProj; // 🔥 necessari per evitar l’error "proj undefined"

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

        if (_lastUserPositions.length >= 2) {
          final prev = _lastUserPositions[_lastUserPositions.length - 2];
          final curr = _lastUserPositions[_lastUserPositions.length - 1];
          userBearing = bearingBetween(prev, curr);
        } else {
          userBearing = bearingBetween(a, p); // fallback
        }

        bestSegmentIndex = i;
        bestT = t;
        bestProj = proj; // 🔥 guardem el millor punt projectat
      }
    }

    return _ClosestResult(
      distance: minDist,
      bearing: segmentBearing,
      userBearing: userBearing,
      segmentIndex: bestSegmentIndex,
      t: bestT,
      projectedPoint: bestProj!, // 🔥 ara sí, sempre definit
    );
  }

  bool _isAtEndOfTrack(_ClosestResult c) {
    if (_distanceProgressOnTrack < 100) return false;

    final imported = ref.read(importedTrackProvider);
    if (imported == null) return false;

    final lastSegment = imported.coordinates.length - 2;

    final isLastSegment = c.segmentIndex == lastSegment;
    final isNearEnd = c.t > 0.95;
    final isCloseEnough = c.distance < 20;

    return isLastSegment && isNearEnd && isCloseEnough;
  }

  bool _isTrendingAway() {
    if (_lastDistances.length < trendWindow) return false;

    int increases = 0;

    for (int i = 1; i < _lastDistances.length; i++) {
      if (_lastDistances[i] > _lastDistances[i - 1]) {
        increases++;
      }
    }

    return increases >= trendWindow - 2;
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
  final int segmentIndex;
  final double t;
  final LatLng projectedPoint;

  _ClosestResult({
    required this.distance,
    required this.bearing,
    required this.userBearing,
    required this.segmentIndex,
    required this.t,
    required this.projectedPoint,
  });
}

final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
