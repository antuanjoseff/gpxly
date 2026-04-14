import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per al HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/native_gps_channel.dart';
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
    final prefs = await SharedPreferences.getInstance();

    // ───────────────────────────────────────────────
    // 0. COMPROVAR SI L'USUARI VOL PRESERVAR EL TRACK
    // ───────────────────────────────────────────────
    final preserve = prefs.getBool("preserve_track_on_start") ?? false;

    if (preserve) {
      // Consumim el flag
      prefs.setBool("preserve_track_on_start", false);

      HapticFeedback.mediumImpact();

      // 0.1 Afegir primer punt inicial (igual que en flux normal)
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

      // 0.2 Iniciar gravació
      notifier.startRecording(context);

      // 0.3 Engegar GPS natiu
      final settings = ref.read(gpsSettingsProvider);
      await NativeGpsChannel.start(
        useTime: settings.useTime,
        seconds: settings.seconds,
        meters: settings.meters,
        accuracy: settings.accuracy,
      );

      // 0.4 Centrar mapa
      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
      ref.read(permissionsProvider.notifier).checkPermissions();
      return;
    }

    // ───────────────────────────────────────────────
    // 1. COMPROVAR CACHE (RECUPERACIÓ NORMAL)
    // ───────────────────────────────────────────────
    if (prefs.containsKey('temp_track_data')) {
      if (!context.mounted) return;

      final recuperar = await AppMessages.showRecoverTrackDialog(context);

      if (recuperar == true) {
        await notifier.loadFromCache();

        await notifier.startRecording(context);

        final settings = ref.read(gpsSettingsProvider);
        await NativeGpsChannel.start(
          useTime: settings.useTime,
          seconds: settings.seconds,
          meters: settings.meters,
          accuracy: settings.accuracy,
        );
        ref.read(permissionsProvider.notifier).checkPermissions();

        return;
      } else {
        await notifier.clearCache();
        notifier.reset();
      }
    }

    // 2. COMPROVAR GPS + PERMISOS (nou flux centralitzat)
    final status = await PermissionsService.checkGpsAndPermissions();

    if (status == GpsPermissionStatus.gpsOff) {
      if (!context.mounted) return;
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) Geolocator.openLocationSettings();
      return;
    }

    if (status == GpsPermissionStatus.permissionDenied) {
      if (!context.mounted) return;

      // Explicació prèvia (ja la tens implementada)
      final continuar = await AppMessages.showPermissionExplanation(context);
      if (continuar != true) return;

      // Flux complet de permisos
      final ok = await PermissionsService.ensurePermissions(context);
      if (!context.mounted || !ok) return;
    }

    // ───────────────────────────────────────────────
    // 4. INICIALITZAR DADES I POSICIÓ INICIAL (FLUX NORMAL)
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
    // 5. INICIAR GRAVACIÓ I SERVEIS NATIUS
    // ───────────────────────────────────────────────
    notifier.startRecording(context);

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    // ───────────────────────────────────────────────
    // 6. MOURE EL MAPA
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
    final notifier = ref.read(trackProvider.notifier);
    notifier.pauseRecording();
    await NativeGpsChannel.stop();
  }

  // --- REPRENDRE ---
  static Future<void> resume(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(trackProvider.notifier);
    notifier.resumeRecording();

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );
  }

  // --- ATURAR I NETEJAR ---
  static Future<void> stop(WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final notifier = ref.read(trackProvider.notifier);
    await notifier.stopRecording();
    await notifier.clearCache();
  }
}
