import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/widgets/recording_status_bar.dart';
import 'menu_tab.dart';

class MenuBar extends ConsumerWidget {
  final bool isChartCollapsed;
  final bool isPanelActive;
  final RecordingState recordingState;
  final NavigationState navState;
  final bool hasTrack;

  final VoidCallback onRecordingTap;
  final VoidCallback onNavigationTap;
  final VoidCallback onToggleChart;

  const MenuBar({
    super.key,
    required this.isChartCollapsed,
    required this.isPanelActive,
    required this.recordingState,
    required this.navState,
    required this.hasTrack,
    required this.onRecordingTap,
    required this.onNavigationTap,
    required this.onToggleChart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final currentDuration = ref.watch(timerProvider);

    final recordingPoints = ref.watch(
      trackRecordingProvider.select((t) => t.points),
    );
    final bool isRecording =
        recordingState == RecordingState.recording ||
        recordingState == RecordingState.paused;
    final bool hasRecordingData = isRecording && recordingPoints.isNotEmpty;

    final bool isProfileAvailable = hasTrack || hasRecordingData;

    final isRunning = ref.watch(locationProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(locationProvider.notifier).isSimulationPaused;

    Widget recordingWidget = MenuTab(
      icon: Icons.fiber_manual_record_outlined,
      label: t.record,
      iconColor: Colors.white,
      onTap: onRecordingTap,
    );

    if (recordingState == RecordingState.recording ||
        recordingState == RecordingState.paused) {
      final bool isRecordingActive = recordingState == RecordingState.recording;
      final Color accentColor = isRecordingActive
          ? Colors.red.shade700
          : Colors.green.shade700;
      final IconData currentIcon = isRecordingActive
          ? Icons.fiber_manual_record
          : Icons.pause_circle_filled_rounded;

      recordingWidget = InkWell(
        onTap: onRecordingTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentIcon, color: accentColor, size: 24),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 2.0,
                horizontal: 6.0,
              ),
              child: TrackDurationTimer(
                state: recordingState,
                duration: currentDuration,
                color: accentColor,
                fontSize: 11,
                showIcon: false,
              ),
            ),
          ],
        ),
      );
    }

    String navigationLabel = t.navigationLoadTrack;
    IconData navigationIcon = Icons.file_upload_outlined;

    if (hasTrack && !navState.isFollowing) {
      navigationLabel = t.navigationFollow;
      navigationIcon = Icons.explore_outlined;
    } else if (navState.isFollowing) {
      navigationLabel = navState.isPaused
          ? t.navigationPaused
          : t.navigationFollowing;
      navigationIcon = navState.isPaused
          ? Icons.explore_outlined
          : Icons.explore;
    }

    Color profileIconColor = Colors.white.withAlpha(60);
    if (isProfileAvailable) {
      if (isChartCollapsed) {
        profileIconColor = Colors.white.withAlpha(200);
      } else {
        profileIconColor = isRunning
            ? (isPaused ? Colors.blue : Colors.orange)
            : Colors.amber;
      }
    }

    return Container(
      color: AppColors.primary,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: recordingWidget),
            const VerticalDivider(color: Colors.white12),

            Expanded(
              child: MenuTab(
                icon: navigationIcon,
                label: navigationLabel,
                iconColor: Colors.white,
                onTap: onNavigationTap,
              ),
            ),
            const VerticalDivider(color: Colors.white12),

            Expanded(
              child: AbsorbPointer(
                absorbing: !isProfileAvailable,
                child: MenuTab(
                  icon: isChartCollapsed
                      ? Icons.landscape_outlined
                      : Icons.landscape_rounded,
                  label: t.menuProfile,
                  iconColor: profileIconColor,
                  onTap: isProfileAvailable ? onToggleChart : null,
                ),
              ),
            ),
            const VerticalDivider(color: Colors.white12),

            Expanded(
              child: MenuTab(
                icon: Icons.settings_outlined,
                label: t.menuSettings,
                iconColor: Colors.white,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
