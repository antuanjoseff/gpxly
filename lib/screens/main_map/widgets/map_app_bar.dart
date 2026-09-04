// lib/widgets/map_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/alarm_settings_notifier.dart';
import 'package:strack_rec/notifiers/gps_accuracy_notifier.dart';
import 'package:strack_rec/notifiers/gps_debug_notifier.dart';
import 'package:strack_rec/notifiers/permissions_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/timer_notifier.dart';
import 'package:strack_rec/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:strack_rec/screens/stats/satellites/screens/satellite_detail_screen.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/utils/gps_accuracy.dart';
import 'package:strack_rec/widgets/recording_status_bar.dart';

class MapAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final double? pressure;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onShareLog;

  const MapAppBar({
    super.key,
    required this.pressure,
    required this.isRunning,
    required this.isPaused,
    required this.onShareLog,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    // 📡 Escuita reactiva de les alarmes de seguretat actives
    final alarms = ref.watch(alarmSettingsProvider);
    final gpsDebugEnabled = ref.watch(gpsDebugProvider);
    final permissions = ref.watch(permissionsProvider);
    final isGpsDisabled =
        !permissions.hasPermission || !permissions.serviceEnabled;
    final gpsAccuracy = ref.watch(gpsAccuracyProvider);
    final gpsAccuracyLevel = ref.watch(gpsAccuracyLevelProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((track) => track.recordingState),
    );
    final recordingDuration = ref.watch(timerProvider);
    final isRecording =
        recordingState == RecordingState.recording ||
        recordingState == RecordingState.paused;
    final recordingColor = recordingState == RecordingState.recording
        ? Colors.red.shade700
        : Colors.amber.shade700;
    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 8,

      centerTitle: false,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icon/strack_rec_mini_icon.png',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'STRec',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      flexibleSpace: isRecording
          ? Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        recordingState == RecordingState.recording
                            ? Icons.fiber_manual_record
                            : Icons.pause_rounded,
                        color: recordingColor,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      TrackDurationTimer(
                        state: recordingState,
                        duration: recordingDuration,
                        color: recordingColor,
                        fontSize: 16,
                        showIcon: false,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,

      actions: [
        if (gpsDebugEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onShareLog,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

        if (anyAlarmActive)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
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
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

        if (isGpsDisabled)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 10.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.redAlert,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.gpsDisabledTitle.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.redAlert,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!isGpsDisabled)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(height: 22, width: 1, color: Colors.white24),
            ),
          ),

        if (!isGpsDisabled)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Precisio GPS i satel·lits',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SatelliteDetailScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  width: 44,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.satellite_alt_rounded,
                        color: _gpsAccuracyColor(gpsAccuracyLevel),
                        size: 25,
                      ),
                      if (gpsAccuracy != 999.0)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Text(
                            '${gpsAccuracy.round()} m',
                            style: TextStyle(
                              color: _gpsAccuracyColor(gpsAccuracyLevel),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(width: 4),
      ],
    );
  }
}

Color _gpsAccuracyColor(GpsAccuracyLevel level) {
  switch (level) {
    case GpsAccuracyLevel.high:
      return const Color(0xFF00FF66);
    case GpsAccuracyLevel.good:
      return const Color(0xFF00E676);
    case GpsAccuracyLevel.medium:
      return const Color(0xFFFFA726);
    case GpsAccuracyLevel.poor:
      return const Color(0xFFFF7043);
    case GpsAccuracyLevel.bad:
      return const Color(0xFFFF1744);
  }
}
