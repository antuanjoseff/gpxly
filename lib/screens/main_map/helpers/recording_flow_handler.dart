// lib/screens/main_screen/helpers/recording_flow_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/services/gpx_exporter.dart';
import 'package:senda/services/recording_handler.dart';
import 'package:senda/services/location_permission_flow.dart';
import 'package:senda/ui/app_messages.dart';

class RecordingFlowHandler {
  final WidgetRef ref;
  final BuildContext context;

  RecordingFlowHandler({required this.ref, required this.context});

  /// Obre la màquina de control de gravació flotant
  Future<void> openRecordingControl({
    required MapLibreMapController? mapController,
    required void Function(bool) onToggleSmartCenter,
    required void Function(LatLng) onUpdateLastCamera,
    required void Function(bool) onToggleProgrammaticMove,
    required void Function(CameraUpdate) safeAnimateCamera,
  }) async {
    final state = ref.read(trackRecordingProvider).recordingState;
    final String? action = await AppMessages.showRecordingControlDialog(
      context: context,
      state: state,
    );

    if (action == null) return;

    switch (action) {
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
        RecordingHandler.pause(ref);
        break;
      case "resume":
        RecordingHandler.resume(ref);
        break;
      case "stop":
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
      ref.read(trackRecordingProvider.notifier).reset();
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
      ref.read(trackRecordingProvider.notifier).reset();
      ref.read(waypointsProvider.notifier).clear();
      ref.read(timerProvider.notifier).reset();
    }
  }
}
