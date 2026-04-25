import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/ui/bottom_bar/pressable_scale.dart';

class BottomBarButtons extends ConsumerWidget {
  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onImportTrack;
  final VoidCallback onFollowTrack;

  const BottomBarButtons({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onImportTrack,
    required this.onFollowTrack,
  });

  @override
  // ... resta del codi igual fins al build
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState = ref.watch(trackFollowNotifierProvider);
    final imported = ref.watch(importedTrackProvider);
    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        children: [
          // --- COLUMNA ESQUERRA: GRAVACIÓ ---
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildRecordingSlot(),
            ),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.black12,
            indent: 20,
            endIndent: 20,
          ),

          // --- COLUMNA DRETA: SEGUIMENT ---
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildFollowingSlot(
                ref,
                hasImported,
                followState.isFollowing,
                followState.isPaused, // 👈 PASSEM L'ESTAT DE PAUSA AQUÍ
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... _buildRecordingSlot es queda igual

  Widget _buildFollowingSlot(
    WidgetRef ref,
    bool hasImported,
    bool isFollowing,
    bool isFollowPaused, // 👈 AFEGIM EL PARÀMETRE AQUÍ
  ) {
    if (!hasImported) {
      return _bigActionButton(
        key: const ValueKey("foll_no_track"),
        label: "Ruta",
        icon: Icons.file_upload,
        color: Colors.blue,
        onTap: onImportTrack,
      );
    }

    if (!isFollowing) {
      return _bigActionButton(
        key: const ValueKey("foll_has_track"),
        label: "Seguir",
        icon: Icons.play_arrow,
        color: Colors.blue,
        onTap: onFollowTrack,
      );
    }

    // 3. Siguiendo ruta activamente
    return _activeControlUI(
      key: const ValueKey("foll_active"),
      title: "SEGUIMENT",
      isPaused: isFollowPaused, // 👈 ARA JA RECONEIX LA VARIABLE
      color: Colors.blue,
      onToggle: () {
        // 👈 CONNECTEM L'ACCIÓ DE PAUSAR
        ref.read(trackFollowNotifierProvider.notifier).togglePause();
      },
      onStop: () {
        ref.read(trackFollowNotifierProvider.notifier).stopFollowing();
        ref.read(importedTrackProvider.notifier).clear();
      },
    );
  }

  // ... resta de components UI igual

  // Lógica de los botones de Grabación
  Widget _buildRecordingSlot() {
    if (state == RecordingState.idle) {
      return _bigActionButton(
        key: const ValueKey("rec_idle"),
        label: "Gravar",
        icon: Icons.fiber_manual_record,
        color: Colors.red,
        onTap: onStart,
      );
    }
    return _activeControlUI(
      key: const ValueKey("rec_active"),
      title: "GRAVACIÓ",
      isPaused: state == RecordingState.paused,
      color: Colors.red,
      onToggle: state == RecordingState.recording ? onPause : onResume,
      onStop: onStop,
    );
  }

  // Lógica de los botones de Seguimiento (CON TU LÓGICA DE RESET)

  // --- COMPONENTES UI (Tu estilo visual solicitado) ---

  Widget _bigActionButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      key: key,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeControlUI({
    required Key key,
    required String title,
    required bool isPaused,
    required Color color,
    required VoidCallback onToggle,
    required VoidCallback onStop,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              color: color,
              onTap: onToggle,
            ),
            _circleButton(icon: Icons.stop, color: color, onTap: onStop),
          ],
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
