import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/waypoints_imported_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
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
              child: _buildRecordingSlot(context),
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
                context,
                ref,
                hasImported,
                followState.isFollowing,
                followState.isPaused,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GRAVACIÓ ---
  // --- GRAVACIÓ (Columna Esquerra) ---
  Widget _buildRecordingSlot(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (state == RecordingState.idle) {
      return _bigActionButton(
        key: const ValueKey("rec_idle"),
        label: t.startRecording,
        icon: Icons.play_arrow_rounded,
        color: Colors.red,
        onTap: onStart,
      );
    }

    return _activeControlUI(
      key: const ValueKey("rec_active"),
      title: t.recording,
      isPaused: state == RecordingState.paused,
      color: Colors.red,
      onToggle: state == RecordingState.recording ? onPause : onResume,
      onStop: onStop,
    );
  }

  // --- SEGUIMENT (Columna Dreta) ---
  Widget _buildFollowingSlot(
    BuildContext context,
    WidgetRef ref,
    bool hasImported,
    bool isFollowing,
    bool isFollowPaused,
  ) {
    final t = AppLocalizations.of(context)!;

    if (!hasImported) {
      return _bigActionButton(
        key: const ValueKey("foll_no_track"),
        label: t.importedTrack,
        icon: Icons.file_upload,
        color: AppColors.deepGreen,
        onTap: onImportTrack,
      );
    }

    if (!isFollowing) {
      return _bigActionButton(
        key: const ValueKey("foll_has_track"),
        label: t.follow,
        icon: Icons.navigation_rounded, // 👈 Manté la icona de navegació
        color: AppColors.deepGreen,
        onTap: onFollowTrack,
      );
    }

    return _activeControlUI(
      key: const ValueKey("foll_active"),
      title: t.following,
      isPaused: isFollowPaused,
      color: AppColors.deepGreen,
      onToggle: () {
        ref.read(trackFollowNotifierProvider.notifier).togglePause();
      },
      onStop: () async {
        // 🔥 CRIDEM AL DIÀLEG DE CONFIRMACIÓ
        final confirm = await AppMessages.showStopFollowingDialog(context);

        if (confirm == true) {
          ref.read(trackFollowNotifierProvider.notifier).stopFollowing();
          ref.read(importedTrackProvider.notifier).clear();
          ref.read(importedWaypointsProvider.notifier).clear();
        }
      },
    );
  }

  // --- Lògica d'icones als controls de pausa ---
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
              // Quan està en pausa, mostrem Play per a gravació i Navegació per a seguiment
              icon: isPaused
                  ? (color == Colors.red
                        ? Icons.play_arrow_rounded
                        : Icons.navigation_rounded)
                  : Icons.pause,
              color: color,
              onTap: onToggle,
            ),
            _circleButton(icon: Icons.stop, color: color, onTap: onStop),
          ],
        ),
      ],
    );
  }

  // --- COMPONENTS UI ---
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
          color: color.withAlpha(26), // 0.1 → 26
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
