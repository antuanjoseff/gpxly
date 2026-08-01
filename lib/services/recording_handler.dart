// lib/services/recording_handler.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
// Importacions de la nova línia de providers estructurada
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1: Hardware GPS
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart'; // Bloc 2: Gravador i Stats
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/services/altitude_logger.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingHandler {
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    print("🔴 [HANDLER] Iniciant funcio start...");

    // ✅ ADAPTAT: Llegim el nou gravador i el node de localització
    final recordingNotifier = ref.read(trackRecordingProvider.notifier);
    final locationNotifier = ref.read(locationProvider.notifier);

    final wpNotifier = ref.read(waypointsProvider.notifier);
    final prefs = await SharedPreferences.getInstance();

    final hasTrackCache = prefs.containsKey('temp_track_data');
    final hasWpCache = await wpNotifier.hasSavedWaypoints();

    // ───────────────────────────────────────────────
    // 1. RECUPERAR TRACK + WAYPOINTS DES DE LA CACHÉ
    // ───────────────────────────────────────────────
    if (hasTrackCache || hasWpCache) {
      print("🔴 [HANDLER] Detectada cache de track.");
      if (!context.mounted) return;

      final recuperar = await AppMessages.showRecoverTrackDialog(context);
      if (recuperar == true) {
        // Carreguem el cache estructurat dins del nou model a través de recordingNotifier
        if (hasTrackCache) await recordingNotifier.loadFromCache();
        if (hasWpCache) wpNotifier.restoreFromPrefs();

        // Abans de continuar, verifiquem permís "Sempre" (per seguretat)
        final ok = await PermissionsService.ensureBackgroundLocationWithDialog(
          context,
        );
        if (!ok) return;

        recordingNotifier.resumeRecording();
        ref.read(timerProvider.notifier).start();

        // ✅ ADAPTAT: Engeguem el NativeGpsChannel a través del nou locationNotifier
        await locationNotifier.ensureGpsStarted();

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
    final serviceStatus = await Permission.location.serviceStatus;
    if (!serviceStatus.isEnabled) {
      print("🔴 [HANDLER] GPS apagat. Aturant i demanant activació.");
      if (!context.mounted) return;
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) {
        ref.read(permissionsProvider.notifier).setPendingAction(true);
        openAppSettings();
      }
      return;
    }

    final ok = await PermissionsService.ensureBackgroundLocationWithDialog(
      context,
    );
    if (!ok) return;

    // ───────────────────────────────────────────────
    // 3. INICIAR GRAVACIÓ NETA
    // ───────────────────────────────────────────────
    HapticFeedback.mediumImpact();

    // Reset i inici del cronòmetre global
    ref.read(timerProvider.notifier).reset();
    ref.read(timerProvider.notifier).start();

    // ✅ ADAPTAT: Iniciem gravació física i engeguem el hardware a través dels nous blocs
    await AltitudeLoggerService().clearLog();
    await AltitudeLoggerService().log("[SESSION] Nova gravacio iniciada");
    recordingNotifier.startRecording();
    await locationNotifier.ensureGpsStarted();

    ref.read(permissionsProvider.notifier).checkPermissions();
    print("🔴 [HANDLER] Tot OK. Començant gravació neta.");
  }

  // ───────────────────────────────────────────────
  // PAUSAR
  // ───────────────────────────────────────────────
  static Future<void> pause(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(timerProvider.notifier).pause();
    ref.read(trackRecordingProvider.notifier).pauseRecording(); // ✅ ADAPTAT
  }

  static Future<void> resume(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(timerProvider.notifier).start();
    ref.read(trackRecordingProvider.notifier).resumeRecording(); // ✅ ADAPTAT
  }

  // ───────────────────────────────────────────────
  // ATURAR (STOP)
  // ───────────────────────────────────────────────
  static Future<void> stop(WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    ref.read(timerProvider.notifier).pause();

    // Passem la durada actual al trackRecordingProvider perquè la guardi definitivament
    final finalDuration = ref.read(timerProvider);
    await ref
        .read(trackRecordingProvider.notifier)
        .stopRecording(finalDuration); // ✅ ADAPTAT

    ref.read(timerProvider.notifier).reset();
  }
}
