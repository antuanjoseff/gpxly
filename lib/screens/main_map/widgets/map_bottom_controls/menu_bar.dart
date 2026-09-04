import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/navigation_state.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/timer_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/screens/settings/settings_screen.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'menu_tab.dart';

class MenuBar extends ConsumerWidget {
  final bool isChartCollapsed;
  final RecordingState recordingState;
  final NavigationState navState;
  final bool hasTrack;

  final VoidCallback onRecordingTap;
  final VoidCallback onNavigationTap;
  final VoidCallback onToggleChart;

  const MenuBar({
    super.key,
    required this.isChartCollapsed,
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

    // 1. --- Pestaña de Grabación (Recording) ---
    Widget recordingWidget;
    if (isRecording) {
      final bool isRecordingActive = recordingState == RecordingState.recording;
      final Color accentColor = isRecordingActive
          ? Colors.red.shade700
          : Colors.amber.shade700;
      final IconData currentIcon = isRecordingActive
          ? Icons.fiber_manual_record
          : Icons.pause_circle_filled_rounded;

      recordingWidget = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRecordingTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentIcon, color: accentColor, size: 22),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    isRecordingActive ? t.recording : t.recordPaused,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      recordingWidget = MenuTab(
        icon: Icons.fiber_manual_record,
        label: t.record,
        iconColor: Colors.white,
        onTap: onRecordingTap,
      );
    }

    // 2. --- Pestaña de Navegación ---
    String navigationLabel = t.navigationLoadTrack;
    IconData navigationIcon = Icons.file_upload_outlined;

    final bool isOffTrack = navState.isFollowing && navState.isOffTrack;

    if (hasTrack && !navState.isFollowing) {
      navigationLabel = t.navigationFollow;
      navigationIcon = Icons.explore_outlined;
    } else if (isOffTrack) {
      navigationLabel = 'Fora\nruta';
      navigationIcon = Icons.explore_off;
    } else if (navState.isFollowing) {
      navigationLabel = navState.isPaused
          ? t.navigationPaused
          : t.navigationFollowing;
      navigationIcon = navState.isPaused
          ? Icons.explore_outlined
          : Icons.explore;
    }

    final Widget navigationWidget = navState.isFollowing
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNavigationTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      navigationIcon,
                      color: isOffTrack
                          ? Colors.red.shade700
                          : navState.isPaused
                          ? Colors.amber.shade700
                          : Colors.green.shade700,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 52,
                      child: Text(
                        navigationLabel,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isOffTrack
                              ? Colors.red.shade700
                              : navState.isPaused
                              ? Colors.amber.shade700
                              : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : MenuTab(
            icon: navigationIcon,
            label: navigationLabel,
            iconColor: Colors.white,
            onTap: onNavigationTap,
          );

    // 3. --- Pestaña del Perfil (Toggle chart) ---
    final bool isOpen = !isChartCollapsed;

    final Widget profileWidget = AbsorbPointer(
      absorbing: !isProfileAvailable,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProfileAvailable ? onToggleChart : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isProfileAvailable
                  ? (isOpen ? Colors.white : AppColors.primary)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOpen ? Icons.landscape_rounded : Icons.landscape_outlined,
                  size: 24,
                  color: isProfileAvailable
                      ? (isOpen ? AppColors.primary : Colors.white)
                      : Colors.white.withAlpha(60),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    t.menuProfile,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isProfileAvailable
                          ? (isOpen ? AppColors.primary : Colors.white)
                          : Colors.white.withAlpha(60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 4. --- Pestaña de Ajustes (Settings) ---
    final Widget settingsWidget = MenuTab(
      icon: Icons.settings_outlined,
      label: t.menuSettings,
      iconColor: Colors.white,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      },
    );

    // --- DISEÑO ESTRUCTURAL FINAL DE LA BARRA INFERIOR ---
    return Container(
      color: AppColors.primary,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: recordingWidget),
            const VerticalDivider(color: Colors.white12, width: 1),

            Expanded(child: navigationWidget),
            const VerticalDivider(color: Colors.white12, width: 1),

            Expanded(child: profileWidget),
            const VerticalDivider(color: Colors.white12, width: 1),

            Expanded(child: settingsWidget),
          ],
        ),
      ),
    );
  }
}
