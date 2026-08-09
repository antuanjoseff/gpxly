// lib/screens/main_screen/helpers/recording_flow_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/timer_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_recorded_notifier.dart';
import 'package:strack_rec/services/gpx_exporter.dart';
import 'package:strack_rec/services/recording_handler.dart';
import 'package:strack_rec/services/location_permission_flow.dart';
import 'package:strack_rec/ui/app_messages.dart';

class RecordingFlowHandler {
  final WidgetRef ref;
  final BuildContext context;

  RecordingFlowHandler({required this.ref, required this.context});

  Future<void> openRecordingControl({
    required MapLibreMapController? mapController,
    required void Function(bool) onToggleSmartCenter,
    required void Function(LatLng) onUpdateLastCamera,
    required void Function(bool) onToggleProgrammaticMove,
    required void Function(CameraUpdate) safeAnimateCamera,
    String?
    action, // 🎯 AFEGIT: Paràmetre opcional per rebre accions directes del submenú
  }) async {
    final state = ref.read(trackRecordingProvider).recordingState;
    String? finalAction = action; // Utilitzem una variable interna combinada

    // 🟢 EL FLUX INTEL·LIGENT DE SENDA:
    // Només obrim el diàleg si no hem rebut cap acció directa forçada del submenú inferior
    if (finalAction == null) {
      if (state == RecordingState.idle) {
        // 1. Si està aturat, inicia la gravació a l'acte [INDEX]
        finalAction = "start";
      } else {
        // 2. Si està en marxa o en pausa, obrim el diàleg de control de Senda [INDEX].
        // Com que l'usuari clica des del submenú inferior de botons de "MapBottomControls",
        // si tria "Pausar" o "Reprendre", farem que s'ho salti directament als mètodes en un futur,
        // però ens assegurem que el cas "stop" obri el diàleg de guardar/compartir de sota! [INDEX]
        finalAction = await AppMessages.showRecordingControlDialog(
          context: context,
          state: state,
        );
      }
    }

    if (finalAction == null) return;

    switch (finalAction) {
      case "start":
        final ok = await requestLocationPermissionsUnified(context, ref);
        if (!ok) return;

        await RecordingHandler.start(context, ref);
        final userGps = ref.read(locationProvider);

        if (mapController != null && userGps != null) {
          onToggleSmartCenter(true);
          onUpdateLastCamera(userGps.position);
          onToggleProgrammaticMove(true);
          safeAnimateCamera(CameraUpdate.newLatLngZoom(userGps.position, 18));
          Future.delayed(
            const Duration(milliseconds: 600),
            () => onToggleProgrammaticMove(false),
          );
        }
        break;

      case "pause":
        // 🟢 DIRECTE: Sense confirmació intermèdia per aturar el ritme [INDEX]
        RecordingHandler.pause(ref);
        break;

      case "resume":
        // 🟢 DIRECTE: Sense confirmació intermèdia per tornar a caminar [INDEX]
        // 🛡️ Ara també es comprova i s'assegura que el GPS estigui actiu en reprendre
        final ok = await requestLocationPermissionsUnified(context, ref);
        if (!ok) return;

        RecordingHandler.resume(ref);
        break;

      case "stop":
        // 🟢 DIÀLEG MANTINGUT: Obre el flux complet de compartir, desar o cancel·lar [INDEX]
        _handleStopProcess();
        break;
    }
  }

  /// Tanca la sessió, gestiona la compartició i el purgat en memòria RAM
  Future<void> _handleStopProcess() async {
    final prefs = await SharedPreferences.getInstance();
    final result = await AppMessages.showStopRecordingDialog(context);
    if (result == null) return;

    final finalDuration = ref.read(timerProvider);
    ref.read(timerProvider.notifier).pause();

    await ref
        .read(trackRecordingProvider.notifier)
        .stopRecording(finalDuration);

    if (result == "share") {
      await shareTrack();
      return;
    }

    final eliminar = await AppMessages.showDeleteTrackDialog(context);
    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);
      await ref.read(trackRecordingProvider.notifier).reset();
      ref.read(waypointsProvider.notifier).clear();
      ref.read(timerProvider.notifier).reset();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }

  Future<void> shareTrack() async {
    final recordingTrack = ref.read(trackRecordingProvider);
    if (recordingTrack.points.isEmpty) return;

    final suggested = buildGpxFilename().replaceAll(".gpx", "");
    final name = await AppMessages.askGpxFilename(context, suggested);
    if (name == null || name.isEmpty) return;

    await exportGpx(name, ref, context);

    final prefs = await SharedPreferences.getInstance();
    final eliminar = await AppMessages.showDeleteTrackDialog(context);

    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);
      await ref.read(trackRecordingProvider.notifier).reset();
      ref.read(waypointsProvider.notifier).clear();
      ref.read(timerProvider.notifier).reset();
    }
  }
}
