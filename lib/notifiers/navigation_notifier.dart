import 'dart:async';

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
import 'helpers/closest_result.dart';
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

  DateTime? _offTrackStart;
  DateTime? _lastOffTrackAlert;

  int maxOffTrackAlerts = 2;
  Duration offTrackCooldown = const Duration(seconds: 20);
  int offTrackAlertsSent = 0;

  bool _offTrackDismissed = false;
  bool _isCurrentlyOffTrack = false;

  bool _hasEverBeenOnTrack = false;
  bool _hasEverBeenOffTrack = false;
  DateTime? _offTrackFirstAlertTime;
  double? _offTrackFirstAlertDistance;

  bool _reverseDetectionLocked = false;
  bool _reverseDialogShown = false;
  bool _offTrackSnackbarShown = false;

  LatLng? _lastProjectedPoint;
  double _distanceProgressOnTrack = 0.0;

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
    _hasEverBeenOffTrack = false;
    offTrackAlertsSent = 0;
    _lastUserPositions.clear();
    _lastDistances.clear();
    _distanceProgressOnTrack = 0.0;
    _lastProjectedPoint = null;
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
    );
    _lastDistances.add(closest.distance);
    _lastProjectedPoint = closest.projectedPoint;
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
    _distanceProgressOnTrack = 0.0;
    _lastProjectedPoint = null;
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
    );

    final proj = closest.projectedPoint;

    // --- PROGRESSIÓ SOBRE EL TRACK MANTINGUDA ---
    if (_lastProjectedPoint != null) {
      final step = calculateDistanceManual(
        // Utilitza el teu utilitari natiu de càlcul entre coordenades
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

    // --- FINAL DEL TRACK ---
    final List<double> lastCoords = imported.coordinates.last;
    final LatLng goalPoint = LatLng(lastCoords[1], lastCoords[0]);

    if (_checkIfFinished(closest, goalPoint, imported.coordinates.length)) {
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

    // --- NIVELL 2: trending away, heading wrong, offtrack bàsic ---
    bool isTrendingAway = false;
    bool isHeadingWrong = false;

    if (count >= TrackThresholds.minPositionsLevel2) {
      isTrendingAway = offtrackLogic.isTrendingAway(_lastDistances);
      isHeadingWrong =
          geometry.headingDifference(closest.bearing, closest.userBearing) > 45;
    }

    // --- NIVELL 3: reverse detection, trending robust ---
    if (count >= TrackThresholds.minPositionsLevel3 &&
        state.mode == FollowMode.onTrack &&
        !_reverseDialogShown &&
        !_reverseDetectionLocked) {
      final headingDiff = geometry.headingDifference(
        closest.bearing,
        closest.userBearing,
      );

      if (isNear &&
          headingDiff > 140 &&
          reverseDetector.isReverseDirection(closest, _lastUserPositions)) {
        _reverseDialogShown = true;
        _reverseDetectionLocked = true;

        state = state.copyWith(showReverseTrackDialog: true);

        // Micro-delay per evitar que el rebuild mati el reproductor
        Future.delayed(const Duration(milliseconds: 30), () {
          sounds.playReversedTrackSound();
        });

        return;
      }
    }

    // --- AUTÒMAT D'ESTATS ---
    _handleFollowState(
      dist: dist,
      isNear: isNear,
      isFar: isFar,
      isTrendingAway: isTrendingAway,
      isHeadingWrong: isHeadingWrong,
    );

    state = state.copyWith(distanceToTrackLine: dist);
  }

  // ─────────────────────────────────────────────────────────────
  // 🤖 L'AUTÒMAT D'ESTATS REUBICAT (_handleFollowState)
  // ─────────────────────────────────────────────────────────────
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
            onUserDriftingAway(dist);
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
  bool _checkIfFinished(ClosestResult closest, LatLng goal, int totalPoints) {
    final double distanceToGoal = calculateDistanceManual(
      closest.projectedPoint.latitude,
      closest.projectedPoint.longitude,
      goal.latitude,
      goal.longitude,
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
    _lastProjectedPoint = null;
    _lastDistances.clear();
    _distanceProgressOnTrack = 0.0;

    _reverseDialogShown = false;
    _reverseDetectionLocked = false;

    state = state.copyWith(showReverseTrackDialog: false);
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

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
    if (state.isPaused) {
      _lastProjectedPoint = null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 🔗 EL PROVEÏDOR GLOBAL DE NAVEGACIÓ SENDA
// ─────────────────────────────────────────────────────────────
final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(() {
      return NavigationNotifier();
    });
