import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (hasTrackCache) {
          await track.loadFromCache();
          // 🔥 Recuperem la durada guardada al timerProvider
          final cachedDuration = ref.read(trackProvider).duration;
          ref.read(timerProvider.notifier).setInitialValue(cachedDuration);
        }

        if (hasWpCache) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            wpNotifier.restoreFromPrefs();
          });
        }

        track.continueRecording();

        // 🔥 Engeguem el cronòmetre des d'on s'havia quedat
        ref.read(timerProvider.notifier).start();

        await ref.read(trackProvider.notifier).ensureGpsStarted();

        HapticFeedback.mediumImpact();
        ref.read(permissionsProvider.notifier).checkPermissions();
        return;
      } else {
        if (hasTrackCache) await prefs.remove('temp_track_data');
        if (hasWpCache) wpNotifier.clear();
      }
    }

    // ───────────────────────────────────────────────
    // 2. PERMISOS I GPS
    // ───────────────────────────────────────────────
    final status = await PermissionsService.checkGpsAndPermissions();

    if (status == GpsPermissionStatus.gpsOff) {
      if (!context.mounted) return;
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) {
        // 🔥 Marquem l'acció pendent perquè s'iniciï sol al tornar
        ref.read(permissionsProvider.notifier).setPendingAction(true);
        // Obrim la configuració fent servir el teu servei
        await PermissionsService.ensureGpsReady(context);
      }
      return;
    }

    if (status == GpsPermissionStatus.permissionDenied) {
      if (!context.mounted) return;

      final continuar = await AppMessages.showPermissionExplanation(context);
      if (continuar != true) return;

      final ok = await PermissionsService.ensurePermissions(context);
      if (!context.mounted || !ok) return;

      // ⚠️ ELIMINAT EL 'return': Ara el codi segueix avall
      // i inicia la gravació sola un cop acceptats els permisos.
    }

    // ───────────────────────────────────────────────
    // 3. INICIAR GRAVACIÓ NETA
    // ───────────────────────────────────────────────
    HapticFeedback.mediumImpact();

    // 🔥 Netegem i engeguem el cronòmetre independent
    ref.read(timerProvider.notifier).reset();
    ref.read(timerProvider.notifier).start();

    await track.startRecording(context);
    await ref.read(trackProvider.notifier).ensureGpsStarted();

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
