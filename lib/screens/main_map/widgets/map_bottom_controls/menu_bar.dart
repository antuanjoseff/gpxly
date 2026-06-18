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
      icon: Icons.fiber_manual_record,
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
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white, // 🟢 Càpsula blanca que aïlla del blau
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentIcon, color: accentColor, size: 22),
                const SizedBox(height: 2),
                Text(
                  isRecordingActive ? t.recording : t.recordPaused,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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

    // 🎯 NETEJA DE VARIABLES SENSE ÚS: Esborrem "profileIconColor" vella que no s'usava

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
                child: InkWell(
                  onTap: isProfileAvailable ? onToggleChart : null,
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 52,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        // 🟢 CORREGIT: El fons serà blanc ÚNICAMENT si el panell està obert visualment (isPanelActive es true)
                        color: (isProfileAvailable && isPanelActive)
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            // 🟢 CORREGIT: Icona plena si el panell està visible de veritat, perfilada si està tancat
                            isPanelActive
                                ? Icons.landscape_rounded
                                : Icons.landscape_outlined,
                            size: 22,
                            // 🟢 CORREGIT: Color adaptatiu dependent en exclusiva de "isPanelActive"
                            color: isProfileAvailable
                                ? (isPanelActive
                                      ? AppColors.primary
                                      : Colors.white)
                                : Colors.white.withAlpha(60),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.menuProfile,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              // 🟢 CORREGIT: Text adaptatiu dependent en exclusiva de "isPanelActive"
                              color: isProfileAvailable
                                  ? (isPanelActive
                                        ? AppColors.primary
                                        : Colors.white)
                                  : Colors.white.withAlpha(60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
