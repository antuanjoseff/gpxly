import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/services/altitude_logger.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/gps_accuracy_bars.dart';
import 'package:senda/screens/settings/settings_screen.dart';

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
    final alarms = ref.watch(alarmSettingsProvider);
    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    return AppBar(
      centerTitle: false,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      leading: const GpsAccuracyBars(),
      title: const Text("SENDA"),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => AltitudeLoggerService().shareLog(),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => AltitudeLoggerService().clearLog(),
        ),
        if (ref.watch(importedTrackProvider) != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
        if (pressure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              "${pressure!.toStringAsFixed(1)} hPa",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        if (anyAlarmActive)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlarmSettingsTab()),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
