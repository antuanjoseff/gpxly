import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track_follow_state.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/gps_manager.dart';

import 'package:gpxly/services/permissions_service.dart';

import 'package:gpxly/utils/geo_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';

// Helpers
import 'helpers/geometry_utils.dart';
import 'helpers/reverse_detector.dart';
import 'helpers/offtrack_logic.dart';
import 'helpers/progress_tracker.dart';
import 'helpers/track_sounds.dart';
import 'helpers/track_debug.dart';
import 'helpers/closest_result.dart';
import 'helpers/thresholds.dart';

enum FollowMode { notFollowing, initializing, onTrack, offTrack }

class TrackFollowNotifier extends Notifier<TrackFollowState> {
  // ------------------------------------------------------------
  // Helpers (Opció A)
  // ------------------------------------------------------------
  final geometry = TrackGeometryUtils();
  final reverseDetector = ReverseDetector();
  final offtrackLogic = OffTrackLogic();
  final progress = ProgressTracker();
  final sounds = TrackSounds();
  final debug = TrackDebug();

  // ------------------------------------------------------------
  // Estat intern
  // ------------------------------------------------------------
  final List<double> _lastDistances = [];
  final List<LatLng> _lastUserPositions = [];

  DateTime? _offTrackStart;
  DateTime? _lastOffTrackAlert;

  int maxOffTrackAlerts = 1;
  Duration offTrackCooldown = Duration(seconds: 20);
  int offTrackAlertsSent = 0;

  bool _offTrackDismissed = false;
  bool _isCurrentlyOffTrack = false;

  bool _hasEverBeenOnTrack = false;
  bool _hasEverBeenOffTrack = false;

  bool _reverseDetectionLocked = false;
  bool _reverseDialogShown = false;
  bool _offTrackSnackbarShown = false;

  bool debugMode = false;

  LatLng? _lastProjectedPoint;
  double _distanceProgressOnTrack = 0.0;

  // ------------------------------------------------------------
  // Build
  // ------------------------------------------------------------
  @override
  TrackFollowState build() {
    return const TrackFollowState(
      isFollowing: false,
      isPaused: false,
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
  // API pública
  // ------------------------------------------------------------
  void toggleFollowing(BuildContext context) {
    if (state.isFollowing) {
      stopFollowing();
    } else {
      startFollowingWithRecording();
    }
  }

  void reverseImportedTrack() {
    // 1. Invertimos las coordenadas en el almacén (Provider)
    ref.read(importedTrackProvider.notifier).reverseTrack();

    // 2. REINICIO CRÍTICO DE MEMORIA
    _lastUserPositions.clear(); // <--- OBLIGATORIO: borra el rumbo antiguo
    _lastProjectedPoint =
        null; // <--- Evita saltos de distancia en el siguiente tick
    _lastDistances.clear(); // <--- Limpia el histórico de "alejamiento"

    // 3. Flags de UI
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;

    // 4. Actualizamos estado
    state = state.copyWith(showReverseTrackDialog: false);
  }

  void dismissReverseTrackDialog() {
    // 🔥 Invertim igualment el track
    ref.read(importedTrackProvider.notifier).reverseTrack();

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

  // ------------------------------------------------------------
  // Seguiment sense enregistrament
  // ------------------------------------------------------------
  Future<void> startFollowingWithoutRecording(
    BuildContext context,
    WidgetRef ref,
    MapLibreMapController? mapController,
  ) async {
    // 1. Permisos igual que RecordingHandler
    final ok = await PermissionsService.ensureGpsReady(context);
    if (!ok) return;

    // 2. Activar GPS via GPSManager
    final gps = ref.read(gpsManagerProvider.notifier);
    final settings = ref.read(gpsSettingsProvider);

    await gps.startGps(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    // 3. Indicar que estem seguint un track
    gps.setFollowing(true);

    // 4. Estat intern
    state = state.copyWith(isFollowing: true, mode: FollowMode.initializing);

    _hasEverBeenOnTrack = false;
    _hasEverBeenOffTrack = false;
    offTrackAlertsSent = 0;

    // 5. Centrar mapa a la posició actual si existeix
    final pos = ref.read(gpsManagerProvider).position;
    if (pos != null && mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(pos));
    }

    // 6. Inicialitzar distància inicial
    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    final first = imported.coordinates.first;
    final firstPos = LatLng(first[1], first[0]);

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = geometry.closestPointAndSegment(
      firstPos,
      importedLatLng,
      _lastUserPositions,
    );

    _lastDistances.clear();
    _lastDistances.add(closest.distance);
  }

  // ------------------------------------------------------------
  // Seguiment amb enregistrament
  // ------------------------------------------------------------
  void startFollowingWithRecording() async {
    final gps = ref.read(gpsManagerProvider.notifier);

    // 1. Indicar que estem seguint un track
    gps.setFollowing(true);

    state = state.copyWith(isFollowing: true, mode: FollowMode.initializing);

    _hasEverBeenOnTrack = false;
    _hasEverBeenOffTrack = false;
    offTrackAlertsSent = 0;

    final track = ref.read(trackProvider);
    final imported = ref.read(importedTrackProvider);

    if (track.coordinates.isEmpty) return;
    if (imported == null || imported.coordinates.isEmpty) return;

    final last = track.coordinates.last;
    final lastPos = LatLng(last[1], last[0]);

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = geometry.closestPointAndSegment(
      lastPos,
      importedLatLng,
      _lastUserPositions,
    );

    _lastDistances.clear();
    _lastDistances.add(closest.distance);
  }

  // ------------------------------------------------------------
  // Aturar seguiment
  // ------------------------------------------------------------
  // Dins de TrackFollowNotifier
  void stopFollowing() {
    final gps = ref.read(gpsManagerProvider.notifier);
    gps.setFollowing(false);

    state = state.copyWith(
      isFollowing: false,
      isPaused: false,
      isOffTrack: false,
      distanceToTrack: 0,
      showOffTrackSnackbar: false,
      mode: FollowMode.notFollowing,
    );

    // NETEJA INTERNA 👈 Molt important per estalviar memòria
    _lastDistances.clear();
    _lastUserPositions.clear();
    _distanceProgressOnTrack = 0.0;
    _lastProjectedPoint = null;
    offTrackAlertsSent = 0;
  }

  // ------------------------------------------------------------
  // Actualitzar posició
  // ------------------------------------------------------------
  void updateUserPosition(LatLng userPos) {
    if (!state.isFollowing || state.isPaused) return;
    if (debugMode) {
      _processDebugPosition(userPos);
      return;
    }

    _lastUserPositions.add(userPos);
    if (_lastUserPositions.length > 10) _lastUserPositions.removeAt(0);

    if (!state.isFollowing) return;

    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = geometry.closestPointAndSegment(
      userPos,
      importedLatLng,
      _lastUserPositions,
    );

    final proj = closest.projectedPoint;

    // Progressió
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

    // Final del track
    if (_checkIfFinished(closest, imported.coordinates.length.toDouble())) {
      HapticFeedback.lightImpact();
      sounds.playEndTrackSound();
      state = state.copyWith(showEndOfTrackSnackbar: true);
      stopFollowing();
      return;
    }

    // Distància
    final dist = closest.distance;
    _lastDistances.add(dist);
    if (_lastDistances.length > TrackThresholds.trendWindow) {
      _lastDistances.removeAt(0);
    }

    final isFar = dist > TrackThresholds.farThreshold;

    // Reversed detection
    // Hem afegit la comprovació de 'dist < TrackThresholds.nearThreshold'
    // i un filtre d'angle estricte per evitar falsos positius en desviaments laterals.
    if (state.mode == FollowMode.onTrack &&
        !_reverseDialogShown &&
        !_reverseDetectionLocked &&
        dist <
            TrackThresholds
                .nearThreshold && // Només si estem realment a prop del track
        geometry.headingDifference(closest.bearing, closest.userBearing) >
            140 && // Angle clarament oposat
        reverseDetector.isReverseDirection(closest, _lastUserPositions)) {
      _reverseDetectionLocked = true;
      sounds.playReversedTrackSound();
      _askUserToReverseTrack();
      return;
    }

    // Autòmat
    _handleFollowState(
      dist: dist,
      isNear: dist < TrackThresholds.nearThreshold,
      isFar: isFar,
      isTrendingAway: offtrackLogic.isTrendingAway(_lastDistances),
      isHeadingWrong:
          geometry.headingDifference(closest.bearing, closest.userBearing) > 45,
    );

    state = state.copyWith(distanceToTrack: dist);
  }

  // ------------------------------------------------------------
  // Autòmat d’estats
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
          DateTime.now().difference(_offTrackStart!) >
              TrackThresholds.offTrackDelay;

      if (isFar && (isTrendingAway || isHeadingWrong || timeExceeded)) {
        if (!_isCurrentlyOffTrack) {
          _isCurrentlyOffTrack = true;
          _offTrackDismissed = false;

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

  // ------------------------------------------------------------
  // Off-track alerts
  // ------------------------------------------------------------
  void onUserDriftingAway() {
    if (_offTrackDismissed) return;

    if (offtrackLogic.canSendOffTrackAlert(
      offTrackAlertsSent,
      maxOffTrackAlerts,
      _lastOffTrackAlert,
      offTrackCooldown,
    )) {
      _lastOffTrackAlert = DateTime.now();
      offTrackAlertsSent++;

      HapticFeedback.heavyImpact();
      sounds.playOffTrackSound();

      if (_offTrackSnackbarShown) return;

      _offTrackSnackbarShown = true;
      state = state.copyWith(showOffTrackSnackbar: true);
    }
  }

  void onUserBackOnTrack() {
    _offTrackDismissed = false;

    HapticFeedback.lightImpact();
    sounds.playBackOnTrackSound();

    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  // ------------------------------------------------------------
  // Reverse dialog
  // ------------------------------------------------------------
  void _askUserToReverseTrack() {
    if (_reverseDialogShown) return;

    _reverseDialogShown = true;
    state = state.copyWith(showReverseTrackDialog: true);
  }

  // ------------------------------------------------------------
  // Final del track
  // ------------------------------------------------------------
  bool _checkIfFinished(ClosestResult closest, double totalPoints) {
    final bool isNearEnd = closest.distance < 15;
    final bool isLastSegment = closest.segmentIndex >= totalPoints - 2;

    const double minProgressRequired = 100.0;
    final bool hasMinimumProgress =
        _distanceProgressOnTrack >= minProgressRequired;

    // SOLO termina si está al final Y ha caminado 100m.
    // Esto evita que se cierre al importar si estás en la meta.
    return isNearEnd && isLastSegment && hasMinimumProgress;
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);

    // Limpiamos el punto de referencia para que al reanudar
    // no calcule un "salto" de distancia erróneo.
    if (state.isPaused) {
      _lastProjectedPoint = null;
    }
  }

  // ------------------------------------------------------------
  // Debug (NO MODIFICAT)
  // ------------------------------------------------------------
  void _processDebugPosition(LatLng userPos) {
    print("--------------------------------------------------");
    print("📍 _processDebugPosition()");
    print("UserPos = $userPos");

    final prevMode = state.mode;
    print("prevMode = $prevMode");

    _lastUserPositions.add(userPos);
    if (_lastUserPositions.length > 10) _lastUserPositions.removeAt(0);
    print("_lastUserPositions = $_lastUserPositions");

    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) {
      print("❌ importedTrack buit — no puc processar");
      return;
    }

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    print("Track length = ${importedLatLng.length}");

    final closest = geometry.closestPointAndSegment(
      userPos,
      importedLatLng,
      _lastUserPositions,
    );
    print("closest.distance = ${closest.distance}");
    print("closest.segmentIndex = ${closest.segmentIndex}");
    print("closest.bearing = ${closest.bearing}");
    print("closest.userBearing = ${closest.userBearing}");
    print("closest.projectedPoint = ${closest.projectedPoint}");

    if (_lastProjectedPoint != null) {
      final step = distanceBetween(
        _lastProjectedPoint!.latitude,
        _lastProjectedPoint!.longitude,
        closest.projectedPoint.latitude,
        closest.projectedPoint.longitude,
      );
      print("step progress = $step");

      if (step > 0 && step < 50) {
        _distanceProgressOnTrack += step;
      }
    }
    _lastProjectedPoint = closest.projectedPoint;

    print("_distanceProgressOnTrack = $_distanceProgressOnTrack");

    final finished = _checkIfFinished(
      closest,
      imported.coordinates.length.toDouble(),
    );
    print("isFinished = $finished");

    if (finished) {
      print("🏁 END OF TRACK DETECTAT");
      HapticFeedback.lightImpact();
      sounds.playBackOnTrackSound();
      state = state.copyWith(showEndOfTrackSnackbar: true);
      return;
    }

    final reversed = reverseDetector.isReverseDirection(
      closest,
      _lastUserPositions,
    );
    print("isReversed = $reversed");
    print("_reverseDialogShown = $_reverseDialogShown");
    print("_reverseDetectionLocked = $_reverseDetectionLocked");

    if (state.mode == FollowMode.onTrack &&
        !_reverseDialogShown &&
        !_reverseDetectionLocked &&
        reversed) {
      print("↩️ REVERSED DETECTAT");
      _reverseDetectionLocked = true;
      _askUserToReverseTrack();
      return;
    }

    final dist = closest.distance;
    _lastDistances.add(dist);
    if (_lastDistances.length > TrackThresholds.trendWindow) {
      _lastDistances.removeAt(0);
    }

    print("_lastDistances = $_lastDistances");
    print("isNear = ${dist < TrackThresholds.nearThreshold}");
    print("isFar = ${dist > TrackThresholds.farThreshold}");
    print("isTrendingAway = ${offtrackLogic.isTrendingAway(_lastDistances)}");
    print(
      "isHeadingWrong = ${geometry.headingDifference(closest.bearing, closest.userBearing) > 45}",
    );

    _handleFollowState(
      dist: dist,
      isNear: dist < TrackThresholds.nearThreshold,
      isFar: dist > TrackThresholds.farThreshold,
      isTrendingAway: offtrackLogic.isTrendingAway(_lastDistances),
      isHeadingWrong:
          geometry.headingDifference(closest.bearing, closest.userBearing) > 45,
    );

    print("newMode = ${state.mode}");

    if (state.mode == prevMode) {
      state = state.copyWith(distanceToTrack: dist);
      print("distanceToTrack actualitzat = $dist");
    } else {
      print("Mode canviat → NO actualitzo distanceToTrack manualment");
    }

    print("--------------------------------------------------");
  }
}

// ------------------------------------------------------------
// Provider
// ------------------------------------------------------------
final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
