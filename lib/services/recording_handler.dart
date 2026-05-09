import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/ui/app_messages.dart';
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
        // (Lògica de recuperació de cache igual...)
        if (hasTrackCache) await track.loadFromCache();
        if (hasWpCache) wpNotifier.restoreFromPrefs();

        // Abans de continuar, verifiquem permís "Sempre" (per seguretat)
        final ok = await PermissionsService.ensureBackgroundLocationWithDialog(
          context,
        );
        if (!ok) return;

        track.continueRecording();
        ref.read(timerProvider.notifier).start();
        await track.ensureGpsStarted(); // Engega el NativeGpsChannel

        HapticFeedback.mediumImpact();
        ref.read(permissionsProvider.notifier).checkPermissions();
        return;
      } else {
        if (hasTrackCache) await prefs.remove('temp_track_data');
        if (hasWpCache) wpNotifier.clear();
      }
    }

    // ───────────────────────────────────────────────
    // 2. GPS I PERMISOS "ALWAYS" (Sense Geolocator)
    // ───────────────────────────────────────────────

    // A) Comprovar si el xip GPS està encès
    final serviceStatus = await Permission.location.serviceStatus;
    if (!serviceStatus.isEnabled) {
      if (!context.mounted) return;
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) {
        ref.read(permissionsProvider.notifier).setPendingAction(true);
        // Obrim ajustos de localització del sistema
        openAppSettings();
      }
      return;
    }

    // B) Diàleg explicatiu + Permís "Sempre"
    final ok = await PermissionsService.ensureBackgroundLocationWithDialog(
      context,
    );
    if (!ok) return;

    // ───────────────────────────────────────────────
    // 3. INICIAR GRAVACIÓ NETA
    // ───────────────────────────────────────────────
    HapticFeedback.mediumImpact();

    // Reset i inici del cronòmetre
    ref.read(timerProvider.notifier).reset();
    ref.read(timerProvider.notifier).start();

    // Iniciem gravació i engeguem el NativeGpsChannel
    await track.startRecording(context);
    await track.ensureGpsStarted();

    // Actualitzem l'estat visual dels permisos al Notifier
    ref.read(permissionsProvider.notifier).checkPermissions();
  }

  // ───────────────────────────────────────────────
  // PAUSAR
  // ───────────────────────────────────────────────
  static Future<void> pause(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(timerProvider.notifier).pause();
    ref.read(trackProvider.notifier).pauseRecording();
  }

  static Future<void> resume(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(timerProvider.notifier).start();
    ref.read(trackProvider.notifier).resumeRecording();
  }

  static Future<void> stop(WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    ref.read(timerProvider.notifier).pause(); // 🔥 Atura cronòmetre

    // Passem la durada actual al trackProvider perquè la guardi definitivament
    final finalDuration = ref.read(timerProvider);
    await ref.read(trackProvider.notifier).stopRecording(finalDuration);

    ref.read(timerProvider.notifier).reset(); // 🔥 Neteja
  }
}
