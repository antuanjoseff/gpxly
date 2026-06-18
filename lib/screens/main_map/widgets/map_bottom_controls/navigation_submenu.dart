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
    final Color fonsDialog = AppColors.skyBlueDark.withAlpha(225);

    return Container(
      child: Row(
        children: [
          // CAS 1: NO HI HA TRACK IMPORTAT (Botó únic sencer arrodonit)
          if (!hasTrack)
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 22),
                label: Text(
                  t.submenuImportGpx.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  onClose();
                  onAction(false);
                },
              ),
            ),

          // CAS 2: HI HA TRACK PERÒ NO S'ESTÀ SEGUINT (Inici vs Paperera)
          if (hasTrack && !isFollowing) ...[
            // ◀️ BOTÓ ESQUERRA: Començar navegació (Verd)
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      topRight: Radius.zero,
                      bottomRight: Radius.zero,
                    ),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  t.navigationStart.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  onClose();
                  onAction(true);
                },
              ),
            ),
            // ▶️ BOTÓ DRETA: Descarta / Esborra GPX (Vermell Alert)
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redAlert,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.zero,
                      bottomLeft: Radius.zero,
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                label: Text(
                  t.navigationCancel.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  onClose();
                  onAction(false);
                },
              ),
            ),
          ],

          // CAS 3: NAVEGACIÓ ACTIVA (Pausa/Reprendre vs Stop)
          if (isFollowing) ...[
            // ◀️ BOTÓ ESQUERRA: Pausa o Reprendre el seguiment
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navState.isPaused
                      ? Colors.green.shade700
                      : Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      topRight: Radius.zero,
                      bottomRight: Radius.zero,
                    ),
                  ),
                ),
                icon: Icon(
                  navState.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: 22,
                ),
                label: Text(
                  (navState.isPaused
                          ? t.submenuFollowingResume
                          : t.submenuFollowingPause)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  onClose();
                  onAction(true);
                },
              ),
            ),
            // ▶️ BOTÓ DRETA: Aturar seguiment (Stop)
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redAlert,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.zero,
                      bottomLeft: Radius.zero,
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                icon: const Icon(Icons.stop_rounded, size: 22),
                label: Text(
                  t.submenuFollowingStop.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () {
                  onClose();
                  onAction(false);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
