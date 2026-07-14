import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// Models immutables refactoritzats
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
// Proveïdors i serveis externs de la teva app
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1
import 'package:senda/services/permissions_service.dart';
import 'package:senda/utils/distance_utils.dart'; // Per al teu mètode calculateDistanceManual / distanceBetween

// Importació dels teus helpers matemàtics i de so reals
import 'helpers/geometry_utils.dart';
import 'helpers/offtrack_logic.dart';
import 'helpers/progress_tracker.dart';
import 'helpers/reverse_detector.dart';
import 'helpers/thresholds.dart';
import 'helpers/track_debug.dart';
import 'helpers/track_sounds.dart';

class NavigationNotifier extends Notifier<NavigationState> {
  // ─── INSTÀNCIES DE LES TEVES CLASSES UTILITÀRIES MANTINGUDES ───
  final geometry = TrackGeometryUtils();
  final reverseDetector = ReverseDetector();
  final offtrackLogic = OffTrackLogic();
  final progress = ProgressTracker();
  final sounds = TrackSounds();
  final debug = TrackDebug();

  // ─── ESTAT INTERN REQUERIT PER ELS TEUS ALGORISMES MANTINGUT AL 100% ───
  final List<double> _lastDistances = [];
  final List<LatLng> _lastUserPositions = [];
  final List<int> _lastSegmentIndices = [];

  DateTime? _offTrackStart;
  DateTime? _lastOffTrackAlert;

  int maxOffTrackAlerts = 2;
  Duration offTrackCooldown = const Duration(seconds: 20);
  int offTrackAlertsSent = 0;

  bool _offTrackDismissed = false;
  bool _isCurrentlyOffTrack = false;

  bool _hasEverBeenOnTrack = false;
  DateTime? _offTrackFirstAlertTime;
  double? _offTrackFirstAlertDistance;

  bool _reverseDetectionLocked = false;
  bool _reverseDialogShown = false;
  bool _offTrackSnackbarShown = false;

  LatLng? _lastProjectedPoint;
  double _distanceProgressOnTrack = 0.0;
  double _reverseDistanceOnTrack = 0.0;
  int? _lastMatchedSegmentIndex;

  @override
  NavigationState build() {
    // 🔗 DATA PIPELINING INTERN: El motor reacciona sol si ens movem i estem navegant
    ref.listen<UserPosition?>(locationProvider, (previous, next) {
      if (next == null || !state.isFollowing || state.isPaused) return;
      _updateUserPositionAndEvaluate(next.position, userHeading: next.heading);
    });

    return NavigationState(
      isFollowing: false,
      isPaused: false,
      isOffTrack: false,
      distanceToTrackLine: 0,
      showOffTrackSnackbar: false,
      showBackOnTrackSnackbar: false,
      showEndOfTrackSnackbar: false,
      showReverseTrackDialog: false,
      mode: FollowMode.notFollowing,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🚀 INICIAR NAVEGACIÓ (startFollowing)
  // ─────────────────────────────────────────────────────────────
  Future<void> startFollowing(
    BuildContext context,
    MapLibreMapController? mapController,
  ) async {
    // 1. Permisos
    final ok = await PermissionsService.ensureGpsReady(context);
    if (!ok) return;

    // Ponemos el GPS en modo "Navegación" usando los umbrales centralizados
    await ref.read(gpsSettingsProvider.notifier).setNavigationMode();
    ref.read(gpsSettingsProvider.notifier).setFollowing(true);

    // 2. Reiniciem variables de control intern de l'autòmat
    _hasEverBeenOnTrack = false;
    offTrackAlertsSent = 0;
    _lastUserPositions.clear();
    _lastSegmentIndices.clear();
    _lastDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _reverseDistanceOnTrack = 0.0;
    _lastProjectedPoint = null;
    _lastMatchedSegmentIndex = null;
    _isCurrentlyOffTrack = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;
    _offTrackSnackbarShown = false;

    state = NavigationState(isFollowing: true, mode: FollowMode.initializing);

    // Centrat inicial del mapa sobre la darrera posició del Bloc 1 (LocationNotifier)
    final currentPos = ref.read(locationProvider)?.position;
    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    if (currentPos != null && mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(currentPos));
    }

    // Inicialització geomètrica del punt projectat més proper de la línia GPX
    final referencePos =
        currentPos ??
        LatLng(imported.coordinates.first[1], imported.coordinates.first[0]);
    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = geometry.closestPointAndSegment(
      referencePos,
      importedLatLng,
      _lastUserPositions,
      preferredSegmentIndex: _lastMatchedSegmentIndex,
      segmentSearchWindow: TrackThresholds.mapMatchSegmentWindow,
    );
    _lastDistances.add(closest.distance);
    _lastProjectedPoint = closest.projectedPoint;
    _lastMatchedSegmentIndex = closest.segmentIndex;
  }

  // ─────────────────────────────────────────────────────────────
  // 🛑 ATURAR NAVEGACIÓ (stopFollowing)
  // ─────────────────────────────────────────────────────────────
  void stopFollowing() {
    ref.read(gpsSettingsProvider.notifier).setFollowing(false);

    // Restaurar la configuració del GPS original de l'usuari
    ref.read(gpsSettingsProvider.notifier).restoreDefaultMode();

    _lastDistances.clear();
    _lastUserPositions.clear();
    _lastSegmentIndices.clear();
    _distanceProgressOnTrack = 0.0;
    _reverseDistanceOnTrack = 0.0;
    _lastProjectedPoint = null;
    _lastMatchedSegmentIndex = null;
    offTrackAlertsSent = 0;
    _offTrackStart = null;
    _isCurrentlyOffTrack = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;
    _offTrackSnackbarShown = false;

    state = NavigationState(mode: FollowMode.notFollowing);
  }

  // ─────────────────────────────────────────────────────────────
  // 📐 EL MOTOR ANALÍTIC CENTRAL (updateUserPosition de l'autòmat)
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // 📐 EL MOTOR ANALÍTIC CENTRAL RECONSTRUÏT AMB PRECISIÓ ABSOLUTA
  // ─────────────────────────────────────────────────────────────
  void _updateUserPositionAndEvaluate(
    LatLng userPos, {
    required double userHeading,
  }) {
    // --- BUFFER DE POSICIONS ---
    _lastUserPositions.add(userPos);
    if (_lastUserPositions.length > TrackThresholds.lastNPositions) {
      _lastUserPositions.removeAt(0);
    }

    final count = _lastUserPositions.length;

    // --- IMPORTED TRACK ---
    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    // --- NIVELL 1: CÀLCULS BÀSICS ---
    final closest = geometry.closestPointAndSegment(
      userPos,
      importedLatLng,
      _lastUserPositions,
      preferredSegmentIndex: _lastMatchedSegmentIndex,
      segmentSearchWindow: TrackThresholds.mapMatchSegmentWindow,
    );
    _lastMatchedSegmentIndex = closest.segmentIndex;
    _lastSegmentIndices.add(closest.segmentIndex);
    if (_lastSegmentIndices.length > TrackThresholds.reverseSegmentWindow) {
      _lastSegmentIndices.removeAt(0);
    }

    final proj = closest.projectedPoint;

    // --- PROGRESSIÓ SOBRE EL TRACK MANTINGUDA ---
    double projectedStep = 0.0;
    if (_lastProjectedPoint != null) {
      final step = calculateDistanceManual(
        _lastProjectedPoint!.latitude,
        _lastProjectedPoint!.longitude,
        proj.latitude,
        proj.longitude,
      );
      if (step > 0 && step < 50) {
        projectedStep = step;
        _distanceProgressOnTrack += step;
      }
    }
    _lastProjectedPoint = proj;

    // --- FINAL DEL TRACK ---
    final List<double> lastCoords = imported.coordinates.last;
    final LatLng goalPoint = LatLng(lastCoords[1], lastCoords[0]);

    if (_checkIfFinished(userPos, goalPoint)) {
      HapticFeedback.lightImpact();
      sounds.playEndTrackSound();
      state = state.copyWith(showEndOfTrackSnackbar: true);
      stopFollowing();
      return;
    }

    // Distància al track i gestió del buffer de tendències
    final dist = closest.distance;
    _lastDistances.add(dist);
    if (_lastDistances.length > TrackThresholds.trendWindow) {
      _lastDistances.removeAt(0);
    }

    final isNear = dist < TrackThresholds.nearThreshold;
    final isFar = dist > TrackThresholds.farThreshold;

    // =========================================================================
    // 🌟 UNIC RETOC COORDENAT: CÀLCUL DEL VECTOR D'AVANÇ REAL EN MAPA
    // =========================================================================
    double rumbRealAvanc = userHeading;
    if (_lastUserPositions.length >= 3) {
      rumbRealAvanc = _calculateHeadingBetweenPoints(
        _lastUserPositions[_lastUserPositions.length - 3],
        _lastUserPositions.last,
      );
    }

    final headingDiff = geometry.headingDifference(
      closest.bearing,
      rumbRealAvanc,
    );
    // =========================================================================

    // Acumulació de metres inversa intel·ligent basada en angles reals de trajectòria
    if (state.mode == FollowMode.onTrack &&
        isNear &&
        projectedStep > 0 &&
        headingDiff > 130) {
      _reverseDistanceOnTrack += projectedStep;
    } else if (headingDiff < 45 && projectedStep > 0) {
      _reverseDistanceOnTrack = 0.0;
    }

    // --- NIVELL 2: trending away, heading wrong, offtrack bàsic ---
    bool isTrendingAway = false;
    bool isHeadingWrong = false;

    if (count >= TrackThresholds.minPositionsLevel2) {
      isTrendingAway = offtrackLogic.isTrendingAway(_lastDistances);
      isHeadingWrong =
          headingDiff > 45; // Actualitzat amb la diferència de trajectòria neta
    }

    // --- NIVELL 3: reverse detection, trending robust ---
    if (_reverseDetectionLocked) {
      return;
    }

    if (count >= TrackThresholds.minPositionsLevel3 &&
        state.mode == FollowMode.onTrack &&
        _reverseDistanceOnTrack >= TrackThresholds.reverseMinDistance &&
        !_reverseDialogShown) {
      final hasReverseSegmentTrend = reverseDetector
          .isReverseSegmentProgression(_lastSegmentIndices);

      // Conservades TOTES les teves condicions originals nítides, utilitzant el headingDiff real de moviment
      if (isNear &&
          headingDiff > 140 &&
          hasReverseSegmentTrend &&
          reverseDetector.isReverseDirection(closest, _lastUserPositions)) {
        _reverseDetectionLocked = true;
        _reverseDialogShown = true;
        state = state.copyWith(showReverseTrackDialog: true);
        return;
      }
    }

    // --- AUTÒMAT D'ESTATS (Passant els paràmetres compilats cap avall) ---
    _handleFollowState(
      dist: dist,
      isNear: isNear,
      isFar: isFar,
      isTrendingAway: isTrendingAway,
      isHeadingWrong: isHeadingWrong,
      calculatedHeading: rumbRealAvanc,
      closestBearing: closest.bearing,
    );

    state = state.copyWith(distanceToTrackLine: dist);
  }

  // ─────────────────────────────────────────────────────────────
  // 🤖 L'AUTÒMAT D'ESTATS REUBICAT (_handleFollowState)
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // 🤖 L'AUTÒMAT D'ESTATS COORDENAT AMB PARÀMETRES DE SUPORT
  // ─────────────────────────────────────────────────────────────
  void _handleFollowState({
    required double dist,
    required bool isNear,
    required bool isFar,
    required bool isTrendingAway,
    required bool isHeadingWrong,
    required double calculatedHeading,
    required double closestBearing,
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
            onUserDriftingAway(dist);
          }
        }
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

      // --- SEGON AVÍS OFFTRACK AL CAP D'1 MINUT I SI ESTÀ MÉS LLUNY ---
      if (_isCurrentlyOffTrack &&
          _offTrackFirstAlertTime != null &&
          _offTrackFirstAlertDistance != null) {
        final elapsed = DateTime.now().difference(_offTrackFirstAlertTime!);

        final bool oneMinutePassed = elapsed > const Duration(minutes: 1);
        final bool isFurtherAway =
            dist > _offTrackFirstAlertDistance! + 3; // +3m marge soroll GPS

        if (oneMinutePassed && isFurtherAway) {
          // Evitem més repeticions fins que torni a ONTRACK
          _offTrackFirstAlertTime = null;
          _offTrackFirstAlertDistance = null;

          HapticFeedback.heavyImpact();
          sounds.playOffTrackSound();

          state = state.copyWith(showOffTrackSnackbar: true);
        }
      }
    }

    state = state.copyWith(mode: newMode, isOffTrack: newIsOffTrack);

    final hasEnteredOnTrack =
        prevMode != FollowMode.onTrack && newMode == FollowMode.onTrack;

    if (hasEnteredOnTrack) {
      // 🟢 MODIFICAT: Escut per evitar esborrar els metres fets si continuem anant al revés
      // Calculem la diferència angular real de reentrada amb la trajectòria de moviment
      final headingDiffCheck = geometry.headingDifference(
        closestBearing,
        calculatedHeading,
      );

      // Només posem a zero si l'usuari avança realment cap endavant a favor del track (<120°)
      if (headingDiffCheck < 120) {
        _reverseDistanceOnTrack = 0.0;
      }

      onUserBackOnTrack();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 🔔 GESTIÓ D'ALERTES D'ALLUNYAMENT (Off-track alerts)
  // ─────────────────────────────────────────────────────────────
  void onUserDriftingAway(double dist) {
    if (_offTrackDismissed) return;

    if (offtrackLogic.canSendOffTrackAlert(
      offTrackAlertsSent,
      maxOffTrackAlerts,
      _lastOffTrackAlert,
      offTrackCooldown,
    )) {
      _lastOffTrackAlert = DateTime.now();
      offTrackAlertsSent++;
      if (_offTrackFirstAlertTime == null) {
        _offTrackFirstAlertTime = DateTime.now();
        _offTrackFirstAlertDistance = dist;
      }

      HapticFeedback.heavyImpact();
      sounds.playOffTrackSound();

      if (_offTrackSnackbarShown) return;

      _offTrackSnackbarShown = true;
      state = state.copyWith(showOffTrackSnackbar: true);
    }
  }

  void onUserBackOnTrack() {
    _offTrackDismissed = false;
    offTrackAlertsSent = 0;
    _offTrackFirstAlertTime = null;
    _offTrackFirstAlertDistance = null;

    HapticFeedback.lightImpact();
    sounds.playBackOnTrackSound();

    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  // ─────────────────────────────────────────────────────────────
  // 🏁 COMPLETAT DE LA RUTA (_checkIfFinished)
  // ─────────────────────────────────────────────────────────────
  bool _checkIfFinished(LatLng userPos, LatLng goalPoint) {
    final double distanceToGoal = calculateDistanceManual(
      userPos.latitude,
      userPos.longitude,
      goalPoint.latitude,
      goalPoint.longitude,
    );

    final bool isAtGoal = distanceToGoal < TrackThresholds.minimumDitanceToGoal;
    final bool hasMinimumProgress =
        _distanceProgressOnTrack >= TrackThresholds.minProgressRequired;

    return isAtGoal && hasMinimumProgress;
  }

  // ─────────────────────────────────────────────────────────────
  // 🎮 API INTERACTIVA DE CONTROL (Giny del Mapa i Diàlegs)
  // ─────────────────────────────────────────────────────────────
  void reverseImportedTrack() {
    ref.read(importedTrackProvider.notifier).reverseTrack();

    _lastUserPositions.clear(); // Borra el rumb antic
    _lastSegmentIndices.clear();
    _lastProjectedPoint = null;
    _lastDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _reverseDistanceOnTrack = 0.0;
    _lastMatchedSegmentIndex = null;

    _reverseDialogShown = false;

    // 🔥 Reprenem el motor després d’un petit delay
    Future.delayed(const Duration(seconds: 3), () {
      _reverseDetectionLocked = false;
    });

    state = state.copyWith(showReverseTrackDialog: false);
  }

  void dismissReverseTrackDialog() {
    _lastUserPositions.clear();
    _lastSegmentIndices.clear();
    _lastDistances.clear();
    _lastProjectedPoint = null;
    _distanceProgressOnTrack = 0.0;
    _reverseDistanceOnTrack = 0.0;
    _lastMatchedSegmentIndex = null;

    _reverseDialogShown = false;
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

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    if (state.isPaused) {
      _lastProjectedPoint = null;
    }
  }

  void unlockReverseDetection() {
    _reverseDetectionLocked = false;
  }

  // 📐 CALCULA EL RUMB REAL D'AVANÇ ENTRE DOS PUNTS GEOMÈTRICS (MÈTODE HAVERSINE VECTOR)
  double _calculateHeadingBetweenPoints(LatLng p1, LatLng p2) {
    final double lat1 = p1.latitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lonDiff = (p2.longitude - p1.longitude) * math.pi / 180;

    final double y = math.sin(lonDiff) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lonDiff);

    // Converteix el radià resultant a graus positius nítids (0 a 360)
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}

// ─────────────────────────────────────────────────────────────
// 🔗 EL PROVEÏDOR GLOBAL DE NAVEGACIÓ SENDA
// ─────────────────────────────────────────────────────────────
final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(() {
      return NavigationNotifier();
    });
