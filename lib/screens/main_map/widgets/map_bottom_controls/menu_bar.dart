import 'package:flutter/material.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'menu_tab.dart';

class MenuBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Recording
    String recordingLabel = t.record;
    IconData recordingIcon = Icons.fiber_manual_record_outlined;
    Color recordingColor = Colors.white;

    if (recordingState == RecordingState.recording) {
      recordingLabel = t.recording;
      recordingIcon = Icons.fiber_manual_record;
      recordingColor = Colors.red;
    } else if (recordingState == RecordingState.paused) {
      recordingLabel = t.recordPaused;
      recordingIcon = Icons.pause_circle_filled_rounded;
      recordingColor = Colors.amber;
    }

    // Navigation
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

    return Container(
      color: AppColors.primary,
      child: Container(
        height: 72, // 1. Augmentat per donar més aire (abans 54 o 64)
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ), // 2. Afegit padding vertical intern pels botons
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            MenuTab(
              icon: recordingIcon,
              label: recordingLabel,
              iconColor: recordingColor,
              onTap: onRecordingTap,
            ),
            const VerticalDivider(color: Colors.white12),

            MenuTab(
              icon: navigationIcon,
              label: navigationLabel,
              iconColor: Colors.white,
              onTap: onNavigationTap,
            ),
            const VerticalDivider(color: Colors.white12),

            MenuTab(
              icon: isChartCollapsed
                  ? Icons.landscape_outlined
                  : Icons.landscape_rounded,
              label: t.menuProfile,
              iconColor: !isPanelActive
                  ? Colors.white24
                  : (isChartCollapsed ? Colors.white70 : Colors.greenAccent),
              onTap: !isPanelActive ? null : onToggleChart,
            ),
            const VerticalDivider(color: Colors.white12),

            MenuTab(
              icon: Icons.settings_outlined,
              label: t.menuSettings,
              iconColor: Colors.white,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
