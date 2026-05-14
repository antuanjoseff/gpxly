import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track_follow_state.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/utils/geo_utils.dart';
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

  int maxOffTrackAlerts = 2;
  Duration offTrackCooldown = Duration(seconds: 20);
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

  void reverseImportedTrack() {
    // 1. Invertimos las coordenadas en el almacén (Provider)
    ref.read(importedTrackProvider.notifier).reverseTrack();

    _lastUserPositions.clear(); // <--- OBLIGATORIO: borra el rumbo antiguo
    _lastProjectedPoint = null;
    _lastDistances.clear();

    _distanceProgressOnTrack = 0.0;

    _reverseDialogShown = false;
    _reverseDetectionLocked = false;

    // 4. Actualizamos estado
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

  // ------------------------------------------------------------
  // Seguiment sense enregistrament
  // ------------------------------------------------------------
  Future<void> startFollowing(
    BuildContext context,
    WidgetRef ref,
    MapLibreMapController? mapController,
  ) async {
    // 1. Permisos
    final ok = await PermissionsService.ensureGpsReady(context);
    if (!ok) return;
    await ref.read(trackProvider.notifier).ensureGpsStarted();

    // 2. Activar mode "following" al TrackNotifier
    // Ponemos el GPS en modo "Navegación" usando los umbrales centralizados
    await ref.read(gpsSettingsProvider.notifier).setNavigationMode();
    ref.read(trackProvider.notifier).setFollowing(true);

    // 3. Estat intern
    state = state.copyWith(isFollowing: true, mode: FollowMode.initializing);

    _hasEverBeenOnTrack = false;
    _hasEverBeenOffTrack = false;
    offTrackAlertsSent = 0;

    // 4. Centrar mapa a la posició actual
    final pos = ref.read(trackProvider).currentPosition;
    if (pos != null && mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(pos));
    }

    // 5. Inicialitzar distància inicial (Millorat)
    final imported = ref.read(importedTrackProvider);
    if (imported == null || imported.coordinates.isEmpty) return;

    // Useu la posició de l'usuari si la tenim, si no, el primer punt del track
    final referencePos =
        pos ??
        LatLng(imported.coordinates.first[1], imported.coordinates.first[0]);

    final importedLatLng = imported.coordinates
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final closest = geometry.closestPointAndSegment(
      referencePos, // <--- Càlcul més real si l'usuari ja és a la ruta
      importedLatLng,
      _lastUserPositions,
    );

    _lastDistances
      ..clear()
      ..add(closest.distance);

    // També és bona idea inicialitzar el punt projectat
    _lastProjectedPoint = closest.projectedPoint;
  }

  // ------------------------------------------------------------
  // Aturar seguiment
  // ------------------------------------------------------------
  void stopFollowing() {
    ref.read(trackProvider.notifier).setFollowing(false);

    // 1. Restaurar la configuració del GPS original de l'usuari
    // Carreguem de Prefs i apliquem al canal natiu
    ref.read(gpsSettingsProvider.notifier).restoreDefaultMode();

    state = state.copyWith(
      isFollowing: false,
      isPaused: false,
      isOffTrack: false,
      distanceToTrack: 0,
      showOffTrackSnackbar: false,
      showBackOnTrackSnackbar: false, // Netegem també aquests flags
      showEndOfTrackSnackbar: false,
      mode: FollowMode.notFollowing,
    );

    // 2. NETEJA INTERNA
    _lastDistances.clear();
    _lastUserPositions.clear();
    _distanceProgressOnTrack = 0.0;
    _lastProjectedPoint = null;
    offTrackAlertsSent = 0;
    _offTrackStart = null; // Important netejar el cronòmetre d'offtrack
    _isCurrentlyOffTrack = false;
    _reverseDialogShown = false;
    _reverseDetectionLocked = false;
  }

  // ------------------------------------------------------------
  // Actualitzar posició
  // ------------------------------------------------------------
  void updateUserPosition(LatLng userPos, {required double userHeading}) {
    if (!state.isFollowing || state.isPaused) return;

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

    // --- NIVELL 1: CÀLCULS BÀSICS (sempre disponibles) ---
    final closest = geometry.closestPointAndSegment(
      userPos,
      importedLatLng,
      _lastUserPositions,
    );

    final proj = closest.projectedPoint;

    // Progressió sobre el track
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
    final List<double> lastCoords = imported.coordinates.last;
    final LatLng goalPoint = LatLng(lastCoords[1], lastCoords[0]);

    if (_checkIfFinished(closest, goalPoint, imported.coordinates.length)) {
      HapticFeedback.lightImpact();
      sounds.playEndTrackSound();
      state = state.copyWith(showEndOfTrackSnackbar: true);
      stopFollowing();
      return;
    }

    // Distància al track
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
        sounds.playReversedTrackSound();

        _reverseDialogShown = true;
        _reverseDetectionLocked = true;

        state = state.copyWith(showReverseTrackDialog: true);
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

  // ------------------------------------------------------------
  // Off-track alerts
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Final del track
  // ------------------------------------------------------------
  bool _checkIfFinished(ClosestResult closest, LatLng goal, int totalPoints) {
    // 1. Distància real a la meta
    final double distanceToGoal = distanceBetween(
      closest.projectedPoint.latitude,
      closest.projectedPoint.longitude,
      goal.latitude,
      goal.longitude,
    );

    final bool isAtGoal = distanceToGoal < TrackThresholds.minimumDitanceToGoal;

    // 2. Progrés mínim realitzat sobre el track
    final bool hasMinimumProgress =
        _distanceProgressOnTrack >= TrackThresholds.minProgressRequired;

    // 3. Nova lògica: només aquestes dues condicions
    return isAtGoal && hasMinimumProgress;
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);

    // Limpiamos el punto de referencia para que al reanudar
    // no calcule un "salto" de distancia erróneo.
    if (state.isPaused) {
      _lastProjectedPoint = null;
    }
  }
}

// ------------------------------------------------------------
// Provider
// ------------------------------------------------------------
final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
