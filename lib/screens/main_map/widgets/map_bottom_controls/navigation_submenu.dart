import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/theme/app_colors.dart';

class NavigationSubMenu extends ConsumerWidget {
  final NavigationState navState;
  final bool hasTrack;
  final void Function(bool) onAction;
  final VoidCallback onClose;

  const NavigationSubMenu({
    super.key,
    required this.navState,
    required this.hasTrack,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final bool isFollowing = navState.isFollowing;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          if (!hasTrack)
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.blueAccent,
                ),
                label: Text(
                  t.submenuImportGpx,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction(false);
                },
              ),
            ),

          if (hasTrack && !isFollowing) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                ),
                label: Text(
                  t.navigationStart,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction(true); // Manté true per començar (Demanarà permisos)
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                label: Text(
                  t.navigationCancel,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction(false); // Neteja el track sense demanar permisos
                },
              ),
            ),
          ],

          if (isFollowing) ...[
            Expanded(
              child: TextButton.icon(
                icon: Icon(
                  navState.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: Colors.amber,
                ),
                label: Text(
                  navState.isPaused
                      ? t.submenuFollowingResume
                      : t.submenuFollowingPause,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction(true);
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.stop_rounded, color: AppColors.redAlert),
                label: Text(
                  t.submenuFollowingStop,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction(
                    false,
                  ); // Atura el seguiment de forma unificada enviant false
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
