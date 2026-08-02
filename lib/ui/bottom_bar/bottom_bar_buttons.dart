// lib/ui/bottom_bar/bottom_bar_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
// ✅ ADAPTAT: Proveïdor analític de navegació que substitueix el trackFollowNotifierProvider
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/services/permissions_service.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/ui/app_messages.dart';
import 'package:strack_rec/ui/bottom_bar/pressable_scale.dart';

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
    // ✅ ADAPTAT: Escoltem l'estat de navegació a través del nou bloc 3 unificat
    final navigationState = ref.watch(navigationProvider);
    final imported = ref.watch(importedTrackProvider);
    final hasImported = imported != null && imported.points.isNotEmpty;

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
                navigationState.isFollowing, // ✅ ADAPTAT
                navigationState.isPaused, // ✅ ADAPTAT
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    final bool isPaused = state == RecordingState.paused;
    return _activeControlUI(
      key: const ValueKey("rec_active"),
      title: isPaused ? t.paused.toUpperCase() : t.recording.toUpperCase(),
      color: Colors.red,
      isPaused: state == RecordingState.paused,
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
      return Column(
        key: const ValueKey("foll_has_track"),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.importedTrack.toUpperCase(),
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
                icon: Icons.navigation_rounded,
                color: AppColors.deepGreen,
                onTap: () async {
                  final ok =
                      await PermissionsService.ensureBackgroundLocationWithDialog(
                        context,
                      );
                  if (!ok) return;

                  onFollowTrack();
                },
              ),
              _circleButton(
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                onTap: () async {
                  final confirm =
                      await AppMessages.showDeleteImportedTrackDialog(context);

                  if (confirm == true) {
                    ref.read(importedTrackProvider.notifier).clear();
                    ref.read(importedWaypointsProvider.notifier).clear();
                  }
                },
              ),
            ],
          ),
        ],
      );
    }

    return _activeControlUI(
      key: const ValueKey("foll_active"),
      title: isFollowPaused
          ? t.paused.toUpperCase()
          : t.following.toUpperCase(),
      isPaused: isFollowPaused,
      color: AppColors.deepGreen,
      onToggle: () {
        // ✅ ADAPTAT: Acció enviada al nou analitzador navigationProvider
        ref.read(navigationProvider.notifier).togglePause();
      },
      onStop: () async {
        final confirm = await AppMessages.showStopFollowingDialog(context);

        if (confirm == true) {
          // ✅ ADAPTAT: Acció enviada al nou analitzador navigationProvider
          ref.read(navigationProvider.notifier).stopFollowing();
          ref.read(importedTrackProvider.notifier).clear();
          ref.read(importedWaypointsProvider.notifier).clear();
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🎮 AUTÒMAT D'ICONES DE CONTROL DE PAUSA / RECUPERACIÓ
  // ─────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // 🎨 COMPONENT VISUAL A: EL GRAN BOTÓ FLOTANT
  // ─────────────────────────────────────────────────────────────
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🎨 COMPONENT VISUAL B: ELS BOTONS CERCLES SECUNDARIS
  // ─────────────────────────────────────────────────────────────
  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
