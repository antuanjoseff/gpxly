import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// Models immutables refactoritzats
import 'package:strack_rec/models/navigation_state.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/notifiers/gps_settings_notifier.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
// Proveïdors i serveis externs de la teva app
import 'package:strack_rec/notifiers/location_notifier.dart'; // Bloc 1
import 'package:strack_rec/services/permissions_service.dart';
import 'package:strack_rec/utils/distance_utils.dart'; // Per al teu mètode calculateDistanceManual / distanceBetween

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
  final List<double> _trackCumulativeDistances = [];

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
  double? _lastAlongTrackDistance;
  double _reverseBackwardAccumMeters = 0.0;
  int? _lastAlongTrackSegmentIndex;
  int? _lastMatchedSegmentIndex;
  int _nextWaypointAlertIndex = 0;

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
    _trackCumulativeDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _lastAlongTrackDistance = null;
    _reverseBackwardAccumMeters = 0.0;
    _lastAlongTrackSegmentIndex = null;
    _lastProjectedPoint = null;
    _lastMatchedSegmentIndex = null;
    _isCurrentlyOffTrack = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;
    _offTrackSnackbarShown = false;
    _nextWaypointAlertIndex = 0;

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

    _trackCumulativeDistances
      ..clear()
      ..addAll(_buildTrackCumulativeDistances(importedLatLng));

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
    _trackCumulativeDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _lastAlongTrackDistance = null;
    _reverseBackwardAccumMeters = 0.0;
    _lastAlongTrackSegmentIndex = null;
    _lastProjectedPoint = null;
    _lastMatchedSegmentIndex = null;
    offTrackAlertsSent = 0;
    _offTrackStart = null;
    _isCurrentlyOffTrack = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;
    _offTrackSnackbarShown = false;
    _nextWaypointAlertIndex = 0;

    state = NavigationState(mode: FollowMode.notFollowing);
  }

  // ─────────────────────────────────────────────────────────────
  // 📐 EL MOTOR ANALÍTIC CENTRAL (updateUserPosition de l'autòmat)
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

    final importedWaypoints = ref.read(importedWaypointsProvider);

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final int? previousMatchedSegmentIndex = _lastMatchedSegmentIndex;

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
    if (_lastProjectedPoint != null) {
      final step = calculateDistanceManual(
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

    if (_trackCumulativeDistances.isEmpty && importedLatLng.length > 1) {
      _trackCumulativeDistances.addAll(
        _buildTrackCumulativeDistances(importedLatLng),
      );
    }

    final distanceAlongTrack = _computeDistanceAlongTrack(
      track: importedLatLng,
      cumulativeDistances: _trackCumulativeDistances,
      segmentIndex: closest.segmentIndex,
      projectedPoint: proj,
    );

    final bool alongTrackPlausible = _isAlongTrackUpdatePlausible(
      currentAlongTrackDistance: distanceAlongTrack,
      currentSegmentIndex: closest.segmentIndex,
      previousMatchedSegmentIndex: previousMatchedSegmentIndex,
    );

    _checkNextWaypointAlarm(
      userPos: userPos,
      imported: imported,
      importedWaypoints: importedWaypoints,
      currentAlongTrackDistance: distanceAlongTrack,
    );

    if (alongTrackPlausible) {
      final prevAlongTrack = _lastAlongTrackDistance;
      if (prevAlongTrack != null) {
        final deltaAlongTrack = distanceAlongTrack - prevAlongTrack;
        const epsilon = TrackThresholds.reverseDeltaEpsilonMeters;

        if (deltaAlongTrack < -epsilon) {
          _reverseBackwardAccumMeters += -deltaAlongTrack;
        } else if (deltaAlongTrack > epsilon) {
          _reverseBackwardAccumMeters = math.max(
            0.0,
            _reverseBackwardAccumMeters - deltaAlongTrack,
          );
        }
      }

      _lastAlongTrackDistance = distanceAlongTrack;
      _lastAlongTrackSegmentIndex = closest.segmentIndex;
    }

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
    // 🌟 CÀLCUL DE RUMB REAL (es manté només per a off-track)
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

    // --- NIVELL 2: trending away, heading wrong, offtrack bàsic ---
    bool isTrendingAway = false;
    bool isHeadingWrong = false;

    if (count >= TrackThresholds.minPositionsLevel2) {
      isTrendingAway = offtrackLogic.isTrendingAway(_lastDistances);
      isHeadingWrong = headingDiff > 55; // Marge suau ampliat per a corbes
    }

    // --- NIVELL 3: REVERSE DETECTION INTEGRADA AMB FILTRE COHERENT ---
    if (_reverseDetectionLocked) {
      return;
    }

    if (count >= TrackThresholds.minPositionsLevel3 &&
        _hasEverBeenOnTrack &&
        state.mode != FollowMode.offTrack &&
        _reverseBackwardAccumMeters >=
            TrackThresholds.reverseBackwardTriggerMeters &&
        !_reverseDialogShown) {
      if (isNear) {
        // 1. Bloquegem immediatament el motor per evitar esdeveniments seqüencials
        _reverseDetectionLocked = true;
        _reverseDialogShown = true;

        // 2. 🔊 DISPAREM EL SO AQUÍ (Funciona a la butxaca a l'acte!)
        sounds.playReversedTrackSound();

        // 3. Notifiquem a la UI que caldrà mostrar el diàleg en tornar
        state = state.copyWith(showReverseTrackDialog: true);
        return;
      }
    }

    // --- AUTÒMAT D'ESTATS NAIUS MANTINGUT AL 100% ---
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
      _reverseBackwardAccumMeters = 0.0;
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

    final imported = ref.read(importedTrackProvider);
    final importedWaypoints = ref.read(importedWaypointsProvider);
    if (imported != null &&
        imported.points.isNotEmpty &&
        importedWaypoints.isNotEmpty) {
      final lastIndex = imported.points.length - 1;
      final reversedWaypoints = importedWaypoints.map((waypoint) {
        final reversedTrackIndex = (lastIndex - waypoint.trackIndex).clamp(
          0,
          lastIndex,
        );
        final reversedPoint = imported.points[reversedTrackIndex];
        return waypoint.copyWith(
          trackIndex: reversedTrackIndex,
          distanceAtPoint: reversedPoint.distanceAtPoint,
        );
      }).toList()..sort((a, b) => a.trackIndex.compareTo(b.trackIndex));

      ref.read(importedWaypointsProvider.notifier).setAll(reversedWaypoints);
    }

    _lastUserPositions.clear(); // Borra el rumb antic
    _lastSegmentIndices.clear();
    _lastProjectedPoint = null;
    _lastDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _trackCumulativeDistances.clear();
    _lastAlongTrackDistance = null;
    _reverseBackwardAccumMeters = 0.0;
    _lastAlongTrackSegmentIndex = null;
    _lastMatchedSegmentIndex = null;
    _nextWaypointAlertIndex = 0;

    if (imported != null && imported.coordinates.length > 1) {
      final importedLatLng = imported.coordinates
          .map((c) => LatLng(c[1], c[0]))
          .toList();
      _trackCumulativeDistances.addAll(
        _buildTrackCumulativeDistances(importedLatLng),
      );
    }

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
    _trackCumulativeDistances.clear();
    _lastAlongTrackDistance = null;
    _reverseBackwardAccumMeters = 0.0;
    _lastAlongTrackSegmentIndex = null;
    _lastMatchedSegmentIndex = null;
    _nextWaypointAlertIndex = 0;

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

  void _checkNextWaypointAlarm({
    required LatLng userPos,
    required Track imported,
    required List<Waypoint> importedWaypoints,
    required double currentAlongTrackDistance,
  }) {
    if (importedWaypoints.isEmpty || imported.points.isEmpty) return;

    if (_nextWaypointAlertIndex >= importedWaypoints.length) {
      _nextWaypointAlertIndex = importedWaypoints.length - 1;
    }

    while (_nextWaypointAlertIndex < importedWaypoints.length) {
      final waypoint = importedWaypoints[_nextWaypointAlertIndex];
      final waypointTrackDistance = _waypointTrackDistance(imported, waypoint);
      if (waypointTrackDistance == null) {
        _nextWaypointAlertIndex++;
        continue;
      }

      if (currentAlongTrackDistance > waypointTrackDistance + 1.0) {
        _nextWaypointAlertIndex++;
        continue;
      }

      final distanceToWaypoint = calculateDistanceManual(
        userPos.latitude,
        userPos.longitude,
        waypoint.lat,
        waypoint.lon,
      );

      if (distanceToWaypoint <= TrackThresholds.waypointAlarmDistanceMeters) {
        HapticFeedback.lightImpact();
        sounds.playWaypointAlarm();
        _nextWaypointAlertIndex++;
      }

      return;
    }
  }

  double? _waypointTrackDistance(Track imported, Waypoint waypoint) {
    if (imported.points.isEmpty) return null;

    final index = waypoint.trackIndex;
    if (index < 0) return null;

    if (index < imported.points.length) {
      return imported.points[index].distanceAtPoint;
    }

    return imported.points.last.distanceAtPoint;
  }

  List<double> _buildTrackCumulativeDistances(List<LatLng> track) {
    if (track.isEmpty) return const [];

    final result = <double>[0.0];
    var acc = 0.0;

    for (int i = 1; i < track.length; i++) {
      acc += calculateDistanceManual(
        track[i - 1].latitude,
        track[i - 1].longitude,
        track[i].latitude,
        track[i].longitude,
      );
      result.add(acc);
    }

    return result;
  }

  double _computeDistanceAlongTrack({
    required List<LatLng> track,
    required List<double> cumulativeDistances,
    required int segmentIndex,
    required LatLng projectedPoint,
  }) {
    if (track.length < 2 || cumulativeDistances.isEmpty) {
      return 0.0;
    }

    final int safeSegment = segmentIndex.clamp(0, track.length - 2);
    final double baseDistance = safeSegment < cumulativeDistances.length
        ? cumulativeDistances[safeSegment]
        : cumulativeDistances.last;

    final double segmentPartialDistance = calculateDistanceManual(
      track[safeSegment].latitude,
      track[safeSegment].longitude,
      projectedPoint.latitude,
      projectedPoint.longitude,
    );

    return baseDistance + segmentPartialDistance;
  }

  bool _isAlongTrackUpdatePlausible({
    required double currentAlongTrackDistance,
    required int currentSegmentIndex,
    required int? previousMatchedSegmentIndex,
  }) {
    final prevAlongTrack = _lastAlongTrackDistance;
    if (prevAlongTrack == null) return true;

    final double delta = (currentAlongTrackDistance - prevAlongTrack).abs();
    final double gpsStep = _estimateLastGpsStepMeters();

    final double maxAllowedDelta =
        TrackThresholds.reverseMaxAlongTrackJumpBaseMeters +
        (gpsStep * TrackThresholds.reverseMaxAlongTrackJumpPerGpsMeter);

    if (delta > maxAllowedDelta) {
      return false;
    }

    final int? prevSegment =
        _lastAlongTrackSegmentIndex ?? previousMatchedSegmentIndex;
    if (prevSegment == null) return true;

    final int segmentJump = (currentSegmentIndex - prevSegment).abs();
    if (gpsStep <= TrackThresholds.reverseSlowStepMeters &&
        segmentJump > TrackThresholds.reverseMaxSegmentJumpWhenSlow) {
      return false;
    }

    return true;
  }

  double _estimateLastGpsStepMeters() {
    if (_lastUserPositions.length < 2) return 0.0;

    final LatLng a = _lastUserPositions[_lastUserPositions.length - 2];
    final LatLng b = _lastUserPositions.last;
    return calculateDistanceManual(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
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
// 🔗 EL PROVEÏDOR GLOBAL DE NAVEGACIÓ STrack Rec
// ─────────────────────────────────────────────────────────────
final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(() {
      return NavigationNotifier();
    });
