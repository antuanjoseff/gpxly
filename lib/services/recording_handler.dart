import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/waypoints_notifier.dart';
import 'package:gpxly/services/gps_manager.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingHandler {
  static Future<void> start(
    BuildContext context,
    WidgetRef ref,
    MapLibreMapController? mapController,
  ) async {
    final notifier = ref.read(trackProvider.notifier);
    final gps = ref.read(gpsManagerProvider.notifier);
    final prefs = await SharedPreferences.getInstance();

    // ───────────────────────────────────────────────
    // 0. PRESERVAR TRACK
    // ───────────────────────────────────────────────
    final preserve = prefs.getBool("preserve_track_on_start") ?? false;

    if (preserve) {
      prefs.setBool("preserve_track_on_start", false);

      // 🔹 NOVETAT: recuperar track des de cache abans de continuar
      final hasTrackCache = prefs.containsKey('temp_track_data');
      if (hasTrackCache) {
        await notifier.loadFromCache();
      }

      HapticFeedback.mediumImpact();

      final pos = await Geolocator.getCurrentPosition();
      final correctedAlt = notifier.localAltitudeCorrection(
        pos.latitude,
        pos.longitude,
      );

      notifier.addCoordinate(
        pos.latitude,
        pos.longitude,
        pos.accuracy,
        correctedAlt,
      );

      notifier.startRecording(context);
      gps.setRecording(true);

      final settings = ref.read(gpsSettingsProvider);
      await gps.startGps(
        useTime: settings.useTime,
        seconds: settings.seconds,
        meters: settings.meters,
        accuracy: settings.accuracy,
      );

      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }

      ref.read(permissionsProvider.notifier).checkPermissions();
      return;
    }

    // ───────────────────────────────────────────────
    // 1. RECUPERAR TRACK + WAYPOINTS DES DE CACHE
    // ───────────────────────────────────────────────
    final wpNotifier = ref.read(waypointsProvider.notifier);
    final hasTrackCache = prefs.containsKey('temp_track_data');
    final hasWpCache = wpNotifier.hasSavedWaypoints;

    if (hasTrackCache || hasWpCache) {
      if (!context.mounted) return;

      final recuperar = await AppMessages.showRecoverTrackDialog(context);

      if (recuperar == true) {
        // TRACK
        if (hasTrackCache) {
          await notifier.loadFromCache();
        }

        // WAYPOINTS (ja carregats automàticament al provider)

        notifier.startRecording(context);
        gps.setRecording(true);

        final settings = ref.read(gpsSettingsProvider);
        await gps.startGps(
          useTime: settings.useTime,
          seconds: settings.seconds,
          meters: settings.meters,
          accuracy: settings.accuracy,
        );

        ref.read(permissionsProvider.notifier).checkPermissions();
        return;
      } else {
        // DESCARTAR-HO TOT
        if (hasTrackCache) {
          await notifier.clearCache();
          notifier.reset();
        }

        if (hasWpCache) {
          wpNotifier.clear(); // també esborra SharedPreferences
        }
      }
    }

    // ───────────────────────────────────────────────
    // 2. PERMISOS
    // ───────────────────────────────────────────────
    final status = await PermissionsService.checkGpsAndPermissions();

    if (status == GpsPermissionStatus.gpsOff) {
      if (!context.mounted) return;
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) Geolocator.openLocationSettings();
      return;
    }

    if (status == GpsPermissionStatus.permissionDenied) {
      if (!context.mounted) return;

      final continuar = await AppMessages.showPermissionExplanation(context);
      if (continuar != true) return;

      final ok = await PermissionsService.ensurePermissions(context);
      if (!context.mounted || !ok) return;
    }

    // ───────────────────────────────────────────────
    // 3. POSICIÓ INICIAL
    // ───────────────────────────────────────────────
    HapticFeedback.mediumImpact();
    notifier.reset();

    final pos = await Geolocator.getCurrentPosition();
    final correctedAlt = notifier.localAltitudeCorrection(
      pos.latitude,
      pos.longitude,
    );

    notifier.addCoordinate(
      pos.latitude,
      pos.longitude,
      pos.accuracy,
      correctedAlt,
    );

    // ───────────────────────────────────────────────
    // 4. INICIAR GRAVACIÓ
    // ───────────────────────────────────────────────
    notifier.startRecording(context);
    gps.setRecording(true);

    // ───────────────────────────────────────────────
    // 5. ACTIVAR GPS (si no està actiu)
    // ───────────────────────────────────────────────
    final settings = ref.read(gpsSettingsProvider);
    await gps.startGps(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    // ───────────────────────────────────────────────
    // 6. CENTRAR MAPA
    // ───────────────────────────────────────────────
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    }

    ref.read(permissionsProvider.notifier).checkPermissions();
  }

  // --- PAUSAR ---
  static Future<void> pause(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(trackProvider.notifier).pauseRecording();
    ref.read(gpsManagerProvider.notifier).setRecording(false);
  }

  // --- REPRENDRE ---
  static Future<void> resume(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(trackProvider.notifier).resumeRecording();
    ref.read(gpsManagerProvider.notifier).setRecording(true);
  }

  // --- ATURAR ---
  static Future<void> stop(WidgetRef ref) async {
    HapticFeedback.heavyImpact();

    final gps = ref.read(gpsManagerProvider.notifier);

    await ref.read(trackProvider.notifier).stopRecording();
    gps.setRecording(false);

    // Si tampoc estàs seguint un track → para el GPS
    if (!gps.following) {
      await gps.stopGps();
    }

    await ref.read(trackProvider.notifier).clearCache();
  }
}
