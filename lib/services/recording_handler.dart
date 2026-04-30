import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/waypoints_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingHandler {
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    final track = ref.read(trackProvider.notifier);
    final wpNotifier = ref.read(waypointsProvider.notifier);
    final prefs = await SharedPreferences.getInstance();

    final hasTrackCache = prefs.containsKey('temp_track_data');
    final hasWpCache = await wpNotifier.hasSavedWaypoints();

    // ───────────────────────────────────────────────
    // 1. RECUPERAR TRACK + WAYPOINTS
    // ───────────────────────────────────────────────
    if (hasTrackCache || hasWpCache) {
      if (!context.mounted) return;

      final recuperar = await AppMessages.showRecoverTrackDialog(context);

      if (recuperar == true) {
        // Recuperar track
        if (hasTrackCache) {
          await track.loadFromCache();
        }

        // Recuperar waypoints
        if (hasWpCache) {
          // Esperem que map_screen hagi carregat capes i estil
          WidgetsBinding.instance.addPostFrameCallback((_) {
            wpNotifier.restoreFromPrefs();
          });
        }

        HapticFeedback.mediumImpact();
        await track.startRecording(context);

        ref.read(permissionsProvider.notifier).checkPermissions();
        return;
      } else {
        // Eliminar track
        if (hasTrackCache) {
          await prefs.remove('temp_track_data');
        }

        // Eliminar waypoints
        if (hasWpCache) {
          wpNotifier.clear();
        }
      }
    }

    // ───────────────────────────────────────────────
    // 2. PERMISOS
    // ───────────────────────────────────────────────
    final status = await PermissionsService.checkGpsAndPermissions();

    if (status == GpsPermissionStatus.gpsOff) {
      if (!context.mounted) return;
      await AppMessages.showGpsDisabledDialog(context);
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
    // 3. INICIAR GRAVACIÓ NETA
    // ───────────────────────────────────────────────
    // ───────────────────────────────────────────────
    // 3. INICIAR GRAVACIÓ NETA
    // ───────────────────────────────────────────────
    HapticFeedback.mediumImpact();
    await track.startRecording(context);

    // 🔥 INICIAR GPS NATIU
    await NativeGpsChannel.start(
      useTime: true,
      seconds: 1,
      meters: 0,
      accuracy: 10,
    );

    // 🔥 CONNECTAR STREAM → TRACKNOTIFIER
    ref.read(trackProvider.notifier).startGpsListener();

    ref.read(permissionsProvider.notifier).checkPermissions();
  }

  // ───────────────────────────────────────────────
  // PAUSAR
  // ───────────────────────────────────────────────
  static Future<void> pause(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(trackProvider.notifier).pauseRecording();
  }

  // ───────────────────────────────────────────────
  // REPRENDRE
  // ───────────────────────────────────────────────
  static Future<void> resume(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(trackProvider.notifier).resumeRecording();
  }

  // ───────────────────────────────────────────────
  // ATURAR
  // ───────────────────────────────────────────────
  static Future<void> stop(WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    await ref.read(trackProvider.notifier).stopRecording();
    // No cal eliminar res: el track queda a prefs fins que l’usuari decideixi
  }
}
