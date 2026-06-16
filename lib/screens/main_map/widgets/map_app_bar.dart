// lib/widgets/map_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/gps_accuracy_bars.dart';
import 'package:senda/widgets/recording_status_bar.dart';

class MapAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final double? pressure;
  final bool isRunning;
  final bool isPaused;

  const MapAppBar({
    super.key,
    required this.pressure,
    required this.isRunning,
    required this.isPaused,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 📡 Escuita reactiva de les alarmes de seguretat actives
    final alarms = ref.watch(alarmSettingsProvider);
    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 16,

      // 🟢 COBERTURA GPS NETEJA: Retorna al seu format estàndard a l'esquerra [INDEX]
      leading: const GpsAccuracyBars(),

      // Forcem el centratge mil·limètric de la telemetria central
      centerTitle: true,

      // ⏱️ CRONÒMETRE I ALTITUD: El mòdul transparent de text gran al cor de la barra [INDEX]
      title: RecordingStatusBar(
        state: ref.watch(
          trackRecordingProvider.select((t) => t.recordingState),
        ),
        duration: ref.watch(timerProvider),
        contentColor: Colors.white, // Sempre blanc pur obligatori [INDEX]
      ),

      actions: [
        // 🟢 NOU EMPLAÇAMENT: La campana de notificació es mou neta i blanca a la dreta [INDEX]
        if (anyAlarmActive)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlarmSettingsTab()),
                );
              },
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white, // Sempre blanc pur obligatori [INDEX]
                  size: 22,
                ),
              ),
            ),
          ),

        // 🛰️ Botó de control del simulador de rutes del track
        if (ref.watch(importedTrackProvider) != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                final notifier = ref.read(locationProvider.notifier);
                if (!isRunning) {
                  final importedData = ref.read(importedTrackProvider);
                  notifier.simulateImportedTrack(importedData);
                } else {
                  notifier.toggleSimulationPause();
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isRunning
                      ? (isPaused ? Colors.blue : Colors.orange)
                      : Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !isRunning
                      ? Icons.play_arrow
                      : (isPaused ? Icons.play_arrow : Icons.pause),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
