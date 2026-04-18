import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/elevation_progress_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import '../theme/app_colors.dart';

class AppMessages {
  // --- Estil de botó reutilitzable per a coherència ---
  static ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // 1. Avís de sortida
  static void showExitWarning(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.exitWarning)));
  }

  // 2. Diàleg de GPS desactivat
  static Future<bool?> showGpsDisabledDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.gpsDisabledTitle),
        content: Text(t.gpsDisabledMessage),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.settings),
          ),
        ],
      ),
    );
  }

  // 3. Diàleg de Recuperació de Ruta
  static Future<bool?> showRecoverTrackDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.mustardYellow),
            const SizedBox(width: 10),
            Text(
              t.recoverTrackTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          t.recoverTrackMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              t.discard,
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.recover),
          ),
        ],
      ),
    );
  }

  // 4. Diàleg d'exportació
  static Future<bool?> showExportDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.exportTitle),
        content: Text(t.exportMessage),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.export),
          ),
        ],
      ),
    );
  }

  // 5. Diàleg de Progrés d'Elevació
  static void showElevationProgressDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final progressState = ref.watch(elevationProgressProvider);
          final hasError = progressState.error != null;

          return AlertDialog(
            backgroundColor: AppColors.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              hasError ? t.error : t.elevationFixing,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasError) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressState.progress,
                      backgroundColor: Colors.white10,
                      color: AppColors.skyBlue,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${(progressState.progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: AppColors.mustardYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.all(16),
            actions: [
              if (hasError)
                ElevatedButton(
                  style: _buttonStyle(AppColors.skyBlue),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(t.close),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- SnackBars ---
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 6. Diàleg de confirmació d'importació GPX
  static Future<bool?> showImportGpxConfirmDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.file_upload_outlined,
              color: AppColors.mustardYellow,
            ),
            const SizedBox(width: 10),
            Text(
              t.importGpxTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          t.importGpxMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              t.cancel,
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.import),
          ),
        ],
      ),
    );
  }

  // 7. Diàleg Mode Visualització
  static Future<bool?> showViewModeDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              color: AppColors.mustardYellow,
            ),
            const SizedBox(width: 10),
            Text(
              t.viewModeTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          t.viewModeMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              t.no,
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.activate),
          ),
        ],
      ),
    );
  }

  // Diàleg explicació permisos
  static Future<bool?> showPermissionExplanation(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.permissionNeededTitle),
        content: Text(t.permissionNeededMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.continueLabel),
          ),
        ],
      ),
    );
  }

  static void showLongPressHint(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.longPressToFinish),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<bool?> showLocationPermissionDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.locationPermissionTitle),
        content: Text(t.locationPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.settings),
          ),
        ],
      ),
    );
  }

  static void showOffTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.offTrack,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                messenger.hideCurrentSnackBar();
                ref
                    .read(trackFollowNotifierProvider.notifier)
                    .dismissOffTrackAlert();
              },
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // 🔥 Reset de flag
    ref.read(trackFollowNotifierProvider.notifier).clearOffTrackSnackbar();
  }

  static void showBackOnTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade700,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.backOnTrack,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                messenger.hideCurrentSnackBar();
                ref
                    .read(trackFollowNotifierProvider.notifier)
                    .dismissBackOnTrackAlert(); // ✔ CORRECTE
              },
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // 🔥 Reset de flag
    ref.read(trackFollowNotifierProvider.notifier).dismissBackOnTrackAlert();
  }
}
