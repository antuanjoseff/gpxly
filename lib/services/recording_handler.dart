import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per al HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
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

        return;
      } else {
        await notifier.clearCache();
        notifier.reset();
      }
    }

    // ───────────────────────────────────────────────
    // 2. COMPROVAR SERVEI GPS
    // ───────────────────────────────────────────────
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      final activate = await AppMessages.showGpsDisabledDialog(context);
      if (activate == true) await Geolocator.openLocationSettings();
      return;
    }

    // ───────────────────────────────────────────────
    // 3. COMPROVAR PERMISOS "SEMPRE"
    // ───────────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      if (!context.mounted) return;
      final continuar = await AppMessages.showPermissionExplanation(context);
      if (continuar != true) return;

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
