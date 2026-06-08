// lib/screens/main_map/widgets/map_bottom_controls.dart (Bloc 1 de 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/screens/main_map/widgets/map_square_button.dart';
import 'package:senda/screens/settings/settings_screen.dart'; // Import per a la navegació [INDEX]

class MapBottomControls extends ConsumerWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final VoidCallback onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;

  const MapBottomControls({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onAddWaypoint,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
  });
  // (Continuació del mètode build dins de map_bottom_controls.dart - Bloc 2 de 2)
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double effectivePadding = systemBottomPadding > 0
        ? systemBottomPadding
        : 16.0;

    final importedTrack = ref.watch(importedTrackProvider);
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;
    final bool isPanelActiveOnScreen =
        hasTrack || recordingState != RecordingState.idle;

    double bottomPosition;
    if (!isPanelActiveOnScreen) {
      bottomPosition = effectivePadding + 12.0;
    } else if (isChartCollapsed) {
      bottomPosition = 38.0 + effectivePadding + 12.0;
    } else {
      bottomPosition = 220.0 + effectivePadding + 12.0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: bottomPosition,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴 1. CONTROL DE GRAVACIÓ (Tipus 3: Acció sòlid de marca) [INDEX]
          MapSquareButton(
            icon: recordingState == RecordingState.recording
                ? Icons.pause_circle_outline
                : (recordingState == RecordingState.paused
                      ? Icons.play_circle_outline
                      : Icons.fiber_manual_record),
            style: MapButtonStyle.action,
            onTap: onOpenRecordingControl,
          ),

          const SizedBox(height: 8),

          // 🧭 2. IMPORTACIÓ / ACCIONS GPX (Tipus 3: Acció sòlid de marca) [INDEX]
          MapSquareButton(
            icon: !hasTrack
                ? Icons.file_upload_outlined
                : (navState.isFollowing
                      ? (navState.isPaused
                            ? Icons.play_arrow_outlined
                            : Icons.pause)
                      : Icons.navigation_rounded),
            style: MapButtonStyle.action,
            onTap: () => onOpenNavigationControl(hasTrack),
          ),

          const SizedBox(height: 8),

          // 🛠️ 3. NOU: BOTÓ DE CONFIGURACIÓ (Tipus 2: Control de Mapa a sota de tot) [INDEX]
          MapSquareButton(
            icon: Icons.settings_outlined,
            style: MapButtonStyle
                .control, // 🔥 Força el disseny elèctric: fons blanc i contorn vermell [INDEX]
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
