import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 AFEGIT
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/l10n/app_localizations.dart';
// Importem el fitxer on tenim el giny del cronòmetre independent
import 'package:senda/widgets/recording_status_bar.dart';
import 'menu_tab.dart';

// 🚀 CANVIAT: De StatelessWidget a ConsumerWidget per poder llegir Riverpod
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
  // 🚀 AFEGIT: El paràmetre WidgetRef ref al mètode build
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    // 🚀 LLEGIM EL CRONÒMETRE: S'actualitzarà automàticament cada segon
    final currentDuration = ref.watch(timerProvider);

    // Recording: Configuració inicial per defecte (Estat None / Idle)
    Widget recordingWidget = MenuTab(
      icon: Icons.fiber_manual_record_outlined,
      label: t.record,
      iconColor: Colors.white,
      onTap: onRecordingTap,
    );

    // 🚀 DISSENY CORREGIT: Icona a dalt i el temps a sota dins d'una Card compacta
    if (recordingState == RecordingState.recording ||
        recordingState == RecordingState.paused) {
      final bool isRecording = recordingState == RecordingState.recording;
      final Color accentColor = isRecording
          ? Colors.red.shade700
          : Colors.green.shade700;
      final IconData currentIcon = isRecording
          ? Icons.fiber_manual_record
          : Icons.pause_circle_filled_rounded;

      recordingWidget = InkWell(
        onTap: onRecordingTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Ocupa el mínim espai vertical possible
          children: [
            // 1. Icona superior alineada amb la resta de la barra
            Icon(
              currentIcon,
              color: accentColor,
              size: 24, // Mida estàndard de les icones del teu menú
            ),
            const SizedBox(height: 4), // Marge mínim entre icona i targeta
            // 2. El temps de gravació a sota amb forma de Card blanca super compacta
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Fons blanc per a la targeta
                borderRadius: BorderRadius.circular(
                  6,
                ), // Cantonades arrodonides d'estil Card
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              // Padding vertical reduït al mínim (2 píxels) i horitzontal just (6 píxels)
              padding: const EdgeInsets.symmetric(
                vertical: 2.0,
                horizontal: 6.0,
              ),
              child: TrackDurationTimer(
                state: recordingState,
                duration: currentDuration,
                color: accentColor, // Text adaptat (vermell o verd)
                fontSize:
                    11, // Mida petita ideal per a l'espai d'una etiqueta de menú
                showIcon: false, // Amaguem la icona interna del temporitzador
              ),
            ),
          ],
        ),
      );
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
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 🚀 1. PESTANYA DE GRAVACIÓ: Ara és dinàmica (MenuTab o el cronòmetre customitzat)
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
              child: MenuTab(
                icon: isChartCollapsed
                    ? Icons.landscape_outlined
                    : Icons.landscape_rounded,
                label: t.menuProfile,
                iconColor: !isPanelActive
                    ? Colors.white24
                    : (isChartCollapsed ? Colors.white70 : Colors.greenAccent),
                onTap: !isPanelActive ? null : onToggleChart,
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
