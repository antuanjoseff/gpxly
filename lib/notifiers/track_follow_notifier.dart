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
    // <--- Afegeix el paràmetre aquí
    if (!state.isFollowing || state.isPaused) return;

    _lastUserPositions.add(userPos);
    if (_lastUserPositions.length > 10) _lastUserPositions.removeAt(0);

    // (Eliminado if redundante de isFollowing que ya estaba arriba)

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
    // Extraiem la meta dinàmicament (sempre és l'últim punt del provider actual)
    final List<double> lastCoords = imported.coordinates.last;
    final LatLng goalPoint = LatLng(lastCoords[1], lastCoords[0]);
    if (_checkIfFinished(closest, goalPoint, imported.coordinates.length)) {
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

    // --- REVERSED DETECTION (MODIFICADO) ---
    // Solo comprobamos si estamos en ruta y no hay un diálogo ya en proceso o bloqueado
    if (state.mode == FollowMode.onTrack &&
        !_reverseDialogShown &&
        !_reverseDetectionLocked) {
      if (dist < TrackThresholds.nearThreshold &&
          geometry.headingDifference(closest.bearing, closest.userBearing) >
              140 &&
          reverseDetector.isReverseDirection(closest, _lastUserPositions)) {
        sounds.playReversedTrackSound();

        // 1. Bloqueamos inmediatamente para que el siguiente tick de GPS no entre aquí
        _reverseDialogShown = true;
        _reverseDetectionLocked = true;

        // 2. Notificamos al estado para que el ref.listen del mapa abra el diálogo
        state = state.copyWith(showReverseTrackDialog: true);

        // Retornamos para evitar que el autómata de estados cambie el modo a OffTrack
        // mientras el usuario decide qué hacer con el diálogo.
        return;
      }
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
    offTrackAlertsSent = 0;
    HapticFeedback.lightImpact();
    sounds.playBackOnTrackSound();

    state = state.copyWith(showBackOnTrackSnackbar: true);
  }

  // ------------------------------------------------------------
  // Reverse dialog
  // ------------------------------------------------------------
  void _askUserToReverseTrack() {
    // Si ya se está mostrando el diálogo O si el usuario ya lo bloqueó
    // en esta sesión (locked), no hacemos NADA.
    if (_reverseDialogShown || _reverseDetectionLocked) return;

    _reverseDialogShown = true;
    _reverseDetectionLocked =
        true; // Bloqueamos nuevas detecciones inmediatamente

    state = state.copyWith(showReverseTrackDialog: true);
  }

  // ------------------------------------------------------------
  // Final del track
  // ------------------------------------------------------------
  bool _checkIfFinished(ClosestResult closest, LatLng goal, int totalPoints) {
    // 1. Distància real (lineal) entre la teva posició projectada i l'últim punt del track.
    // Utilitzem el punt projectat per a major precisió sobre la traça.
    final double distanceToGoal = distanceBetween(
      closest.projectedPoint.latitude,
      closest.projectedPoint.longitude,
      goal.latitude,
      goal.longitude,
    );

    // 2. Umbral de proximitat a la meta (20 metres).
    final bool isAtGoal = distanceToGoal < 20;

    // 3. Progrés mínim realitzat sobre el track (100 metres).
    // Evita que el track s'aturi només començar si la sortida i meta estan juntes.
    const double minProgressRequired = 100.0;
    final bool hasMinimumProgress =
        _distanceProgressOnTrack >= minProgressRequired;

    // 4. Validació per segment (estar al darrer 20% del fitxer).
    // Això garanteix que l'usuari ha recorregut la major part del fitxer de coordenades.
    final bool isLastPart = closest.segmentIndex > (totalPoints * 0.8);

    // Només retornem 'true' si es compleixen totes les condicions simultàniament.
    return isAtGoal && hasMinimumProgress && isLastPart;
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
