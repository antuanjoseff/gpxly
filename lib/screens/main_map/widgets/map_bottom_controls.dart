// lib/screens/main_map/widgets/map_bottom_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';

class MapBottomControls extends ConsumerWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final VoidCallback onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;
  final Widget Function({required IconData icon, required VoidCallback onTap})
  buildSquareButton;

  const MapBottomControls({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onAddWaypoint,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
    required this.buildSquareButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ Filtre de seguretat per assegurar marge en el primer fotograma
    final double effectivePadding = systemBottomPadding > 0
        ? systemBottomPadding
        : 16.0;

    // Escuchamos de forma reactiva los estados que deciden la existencia de la manivela
    final importedTrack = ref.watch(importedTrackProvider);
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;

    // 🧭 DETECCIO DE PRESENCIA DE LA MANIVELA (Si es grava o hi ha ruta, el panell existeix)
    // ✅ CORREGIT: El teu estat de repòs inicial a Senda és 'none' (evita el salt en fals)
    final bool isPanelActiveOnScreen =
        hasTrack || recordingState != RecordingState.idle;

    // 📐 CÁLCULO DE LA COTA DINÁMICA DE LOS TRES ESTADOS SIMÉTRICOS
    double bottomPosition;

    if (!isPanelActiveOnScreen) {
      // ESTAT 1: Todo oculto. Botones abajo en el área segura de la pantalla
      bottomPosition = effectivePadding + 12.0;
    } else if (isChartCollapsed) {
      // ESTAT 2: Panel minimizado. Botones suben sobre la manivela (Alçada 38)
      bottomPosition = 38.0 + effectivePadding + 12.0;
    } else {
      // ESTAT 3: Panel expandido. Botones suben sobre el gráfico completo (Alçada 220)
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
          // 🔴 1. CONTROL DE GRAVACIÓ
          buildSquareButton(
            icon: recordingState == RecordingState.recording
                ? Icons.pause_circle_outline
                : (recordingState == RecordingState.paused
                      ? Icons.play_circle_outline
                      : Icons.fiber_manual_record),
            onTap: onOpenRecordingControl,
          ),

          const SizedBox(height: 8),

          // 🧭 2. IMPORTACIÓ / ACCIONS GPX
          buildSquareButton(
            icon: !hasTrack
                ? Icons.file_upload_outlined
                : (navState.isFollowing
                      ? (navState.isPaused
                            ? Icons.play_arrow_outlined
                            : Icons.pause)
                      : Icons.navigation_rounded),
            onTap: () => onOpenNavigationControl(hasTrack),
          ),
        ],
      ),
    );
  }
}
