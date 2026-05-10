import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/elevation_progress_notifier.dart';
import 'package:senda/notifiers/track_follow_notifier.dart';
import 'package:senda/theme/app_colors.dart';

class AppMessages {
  // ==========================================
  // 1. ESTILS I COLORS (Estètica de l'App)
  // ==========================================
  static const Color _surfaceColor = Color(0xFF242426);
  static final Color _secondaryText = Colors.white.withAlpha(170);

  static ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  // ==========================================
  // 2. MÈTODE MASTER (Per a diàlegs estàndard)
  // ==========================================
  static Future<bool?> _showBaseDialog({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String? confirmLabel,
    Color? confirmColor,
    String? cancelLabel,
    bool barrierDismissible = true,
    List<Widget>? extraContent,
  }) {
    final t = AppLocalizations.of(context)!;
    final Color accentColor = confirmColor ?? AppColors.skyBlue;

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? accentColor, size: 26),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              if (extraContent != null) ...[
                if (message.isNotEmpty) const SizedBox(height: 20),
                ...extraContent,
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (cancelLabel != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(color: Colors.white.withAlpha(130)),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: _buttonStyle(accentColor),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel ?? t.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. DIÀLEGS ADAPTATS AMB BASEDIALOG
  // ==========================================
  static Future<bool?> showGpsDisabledDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.gpsDisabledTitle,
        message: AppLocalizations.of(context)!.gpsDisabledMessage,
        icon: Icons.location_off,
        iconColor: Colors.orangeAccent,
        confirmLabel: AppLocalizations.of(context)!.settings,
      );
  static Future<bool?> showRecoverTrackDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        barrierDismissible: false,
        title: AppLocalizations.of(context)!.recoverTrackTitle,
        message: AppLocalizations.of(context)!.recoverTrackMessage,
        icon: Icons.history,
        confirmLabel: AppLocalizations.of(context)!.recover,
        cancelLabel: AppLocalizations.of(context)!.discard,
      );
  static Future<bool?> showExportDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.exportTitle,
        message: AppLocalizations.of(context)!.exportMessage,
        icon: Icons.ios_share,
        confirmLabel: AppLocalizations.of(context)!.export,
      );
  static Future<bool?> showImportGpxConfirmDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.importGpxTitle,
        message: AppLocalizations.of(context)!.importGpxMessage,
        icon: Icons.file_upload_outlined,
        confirmLabel: AppLocalizations.of(context)!.import,
      );
  static Future<bool?> showViewModeDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.viewModeTitle,
        message: AppLocalizations.of(context)!.viewModeMessage,
        icon: Icons.visibility_outlined,
        confirmLabel: AppLocalizations.of(context)!.activate,
        cancelLabel: AppLocalizations.of(context)!.no,
      );
  static Future<bool?> showReverseTrackDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        barrierDismissible: false,
        title: AppLocalizations.of(context)!.reverseTrackTitle,
        message: AppLocalizations.of(context)!.reverseTrackMessage,
        icon: Icons.swap_vert,
        confirmLabel: AppLocalizations.of(context)!.reverseTrackConfirm,
        cancelLabel: AppLocalizations.of(context)!.ignoreTrackReverse,
      );
  static Future<bool?> showStopFollowingDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.stopFollowingTitle,
        message: AppLocalizations.of(context)!.stopFollowingMessage,
        icon: Icons.stop_circle_outlined,
        iconColor: Colors.redAccent,
        confirmLabel: AppLocalizations.of(context)!.stopFollowing,
      );
  static Future<bool?> showPermissionExplanation(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.permissionNeededTitle,
        message: AppLocalizations.of(context)!.permissionNeededMessage,
        icon: Icons.info_outline,
        confirmLabel: AppLocalizations.of(context)!.continueLabel,
      );
  static Future<bool?> showLocationPermissionDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.locationPermissionTitle,
        message: AppLocalizations.of(context)!.locationPermissionMessage,
        icon: Icons.location_on_outlined,
        confirmLabel: AppLocalizations.of(context)!.settings,
      );
  static Future<bool?> showGpsOptimizationDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.gpsOptimizationTitle,
        message: AppLocalizations.of(context)!.gpsOptimizationMessage,
        icon: Icons.bolt_rounded,
        iconColor: Colors.amberAccent,
        confirmLabel: AppLocalizations.of(context)!.confirm,
        cancelLabel: AppLocalizations.of(context)!.cancel,
      );
  static Future<bool?> showPendingChangesDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        barrierDismissible: false,
        title: AppLocalizations.of(context)!.pendingChangesTitle,
        message: AppLocalizations.of(context)!.pendingChangesMessage,
        icon: Icons.info_outline,
        confirmLabel: AppLocalizations.of(context)!.apply,
        cancelLabel: AppLocalizations.of(context)!.discard,
      );
  static Future<bool?> showNotificationPermissionDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        barrierDismissible: false,
        title: AppLocalizations.of(context)!.notificationPermissionTitle,
        message: AppLocalizations.of(context)!.notificationPermissionMessage,
        icon: Icons.notifications_active_outlined,
        confirmLabel: AppLocalizations.of(context)!.understood,
      );
  static Future<bool?> showDeleteTrackDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: "Eliminar dades?",
        message: "Vols eliminar la informació actual del track?",
        icon: Icons.delete_forever,
        iconColor: Colors.redAccent,
        confirmLabel: "ELIMINAR",
        confirmColor: Colors.redAccent,
        cancelLabel: "MANTENIR",
        barrierDismissible: false,
      );
  static Future<bool?> showDeleteImportedTrackDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.deleteTrackTitle,
        message: AppLocalizations.of(context)!.deleteTrackMessage,
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.redAccent,
        confirmLabel: AppLocalizations.of(context)!.deleteTrackConfirm,
        confirmColor: Colors.redAccent,
        cancelLabel: AppLocalizations.of(context)!.cancel,
      );

  // ==========================================
  // 4. DIÀLEGS AMB ESTRUCTURA ESPECÍFICA
  // ==========================================
  static Future<void> showWaypointDetails(
    BuildContext context,
    Waypoint wp,
    Duration? elapsed,
  ) {
    final t = AppLocalizations.of(context)!;

    String? formattedDuration;
    if (elapsed != null) {
      formattedDuration =
          "${elapsed.inHours.toString().padLeft(2, '0')}:${elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }

    return _showBaseDialog(
      context: context,
      title: t.waypointDetailsTitle,
      message: "",
      icon: Icons.place_rounded,
      iconColor: AppColors.skyBlue,
      extraContent: [
        _buildDetailItem(t.waypointName, wp.name, Icons.label_outline),
        _buildDetailItem(
          t.waypointAltitude,
          "${wp.ele?.toStringAsFixed(0) ?? '---'} m",
          Icons.height,
        ),
        _buildDetailItem(
          t.waypointTrackPoint,
          "#${wp.trackIndex}",
          Icons.timeline,
        ),
        if (wp.distanceAtPoint != null)
          _buildDetailItem(
            t.waypointDistance,
            "${(wp.distanceAtPoint! / 1000).toStringAsFixed(2)} km",
            Icons.route_outlined,
          ),
        if (formattedDuration != null)
          _buildDetailItem(
            t.waypointTime,
            formattedDuration,
            Icons.timer_outlined,
          ),
      ],
    );
  }

  static Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Més espai entre blocs
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.skyBlue.withAlpha(180)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500, // Títol més destacat
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<String?> showStopRecordingDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    // IMPORTANT: Fem servir showDialog directament o un _showBaseDialog
    // que ens permeti capturar qualsevol tipus de retorn (String)
    final dynamic result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.stop_circle_rounded,
              color: Colors.redAccent,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.finishRecordingTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.finishRecordingMessage,
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 1. COMPARTIR (Verd - Amplada total)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, "share"),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    t.shareTrack,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: _buttonStyle(const Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 12),

              // 2. FINALITZAR (Vermell suau - Amplada total)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, "finish"),
                  style: _buttonStyle(Colors.redAccent.withAlpha(40)).copyWith(
                    foregroundColor: WidgetStateProperty.all(Colors.redAccent),
                  ),
                  child: Text(
                    t.finishRecordingConfirm,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. CONTINUAR (Text central)
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  t.continueRecording,
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Retornem el String directament ("share", "finish" o null)
    return result as String?;
  }

  static Future<String?> askGpxFilename(
    BuildContext context,
    String suggestedName,
  ) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: suggestedName);
    final bool? confirmed = await _showBaseDialog(
      context: context,
      title: t.gpxFilenameTitle,
      message: "",
      icon: Icons.edit_note_rounded,
      confirmLabel: t.export,
      extraContent: [
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: t.gpxFilenameLabel,
            suffixText: '.gpx',
            labelStyle: TextStyle(color: AppColors.skyBlue),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
    return confirmed == true ? controller.text : null;
  }

  static Future<String?> showAddWaypointDialog(
    BuildContext context, {
    required String suggestedName,
  }) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: suggestedName);
    final bool? confirmed = await _showBaseDialog(
      context: context,
      title: t.waypointNameTitle,
      message: "",
      icon: Icons.add_location_alt_outlined,
      extraContent: [
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t.waypointNameHint,
            hintStyle: const TextStyle(color: Colors.white30),
          ),
        ),
      ],
    );
    return confirmed == true ? controller.text : null;
  }

  // ==========================================
  // 5. SNACKBARS
  // ==========================================
  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Widget? trailing,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String msg) =>
      _showCustomSnackBar(
        context,
        message: msg,
        backgroundColor: Colors.green.shade700,
        icon: Icons.check_circle,
      );
  static void showErrorSnackBar(BuildContext context, String msg) =>
      _showCustomSnackBar(
        context,
        message: msg,
        backgroundColor: Colors.red.shade700,
        icon: Icons.error_outline,
      );
  static void showExitWarning(BuildContext context) => _showCustomSnackBar(
    context,
    message: AppLocalizations.of(context)!.exitWarning,
    backgroundColor: Colors.green.shade700,
    icon: Icons.exit_to_app,
  );
  static void showLongPressHint(BuildContext context) => _showCustomSnackBar(
    context,
    message: AppLocalizations.of(context)!.longPressToFinish,
    backgroundColor: Colors.orange.shade700,
    duration: const Duration(seconds: 2),
  );
  static void showEndOfTrackSnackBar(BuildContext context) =>
      _showCustomSnackBar(
        context,
        message: AppLocalizations.of(context)!.endOfTrack,
        backgroundColor: AppColors.skyBlue,
        icon: Icons.flag_rounded,
      );
  static void showOffTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) => _showCustomSnackBar(
    context,
    message: AppLocalizations.of(context)!.offTrack,
    backgroundColor: Colors.red.shade800,
    icon: Icons.warning,
    duration: const Duration(days: 1),
    trailing: IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ref.read(trackFollowNotifierProvider.notifier).dismissOffTrackAlert();
      },
    ),
  );
  static void showBackOnTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) => _showCustomSnackBar(
    context,
    message: AppLocalizations.of(context)!.backOnTrack,
    backgroundColor: Colors.green.shade700,
    icon: Icons.check_circle,
    trailing: IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ref
            .read(trackFollowNotifierProvider.notifier)
            .dismissBackOnTrackAlert();
      },
    ),
  );
}
