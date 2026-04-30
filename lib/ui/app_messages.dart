import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/elevation_progress_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class AppMessages {
  // ==========================================
  // 1. ESTILS BASE (Configuració Global)
  // ==========================================

  static ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // ==========================================
  // 2. MÈTODES "MASTER" (Unificació de UI)
  // ==========================================

  static Future<bool?> _showBaseDialog({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String? confirmLabel,
    String? cancelLabel,
    bool barrierDismissible = true,
    List<Widget>? extraContent,
  }) {
    final t = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.skyBlue, size: 28),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              ...extraContent,
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
        actions: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (cancelLabel != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(color: Colors.white.withAlpha(150)),
                  ),
                ),

              // Botó únic quan cancelLabel == null
              ElevatedButton(
                style: _buttonStyle(AppColors.skyBlue),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel ?? t.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    Widget? trailing,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
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

  // ==========================================
  // 3. DIÀLEGS DE CONFIRMACIÓ
  // ==========================================

  static Future<bool?> showGpsDisabledDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.gpsDisabledTitle,
      message: t.gpsDisabledMessage,
      icon: Icons.location_off,
      iconColor: Colors.orangeAccent,
      confirmLabel: t.settings,
    );
  }

  static Future<bool?> showRecoverTrackDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      barrierDismissible: false,
      title: t.recoverTrackTitle,
      message: t.recoverTrackMessage,
      icon: Icons.history,
      confirmLabel: t.recover,
      cancelLabel: t.discard,
    );
  }

  static Future<bool?> showExportDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.exportTitle,
      message: t.exportMessage,
      icon: Icons.ios_share,
      confirmLabel: t.export,
    );
  }

  static Future<bool?> showImportGpxConfirmDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.importGpxTitle,
      message: t.importGpxMessage,
      icon: Icons.file_upload_outlined,
      confirmLabel: t.import,
    );
  }

  static Future<bool?> showViewModeDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.viewModeTitle,
      message: t.viewModeMessage,
      icon: Icons.visibility_outlined,
      confirmLabel: t.activate,
      cancelLabel: t.no,
    );
  }

  static Future<bool?> showReverseTrackDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      barrierDismissible: false,
      title: t.reverseTrackTitle,
      message: t.reverseTrackMessage,
      icon: Icons.swap_vert,
      confirmLabel: t.activate,
    );
  }

  static Future<bool?> showStopFollowingDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.stopFollowingTitle,
      message: t.stopFollowingMessage,
      icon: Icons.stop_circle_outlined,
      iconColor: Colors.redAccent,
      confirmLabel: t.stopFollowing,
    );
  }

  static Future<bool?> showPermissionExplanation(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.permissionNeededTitle,
      message: t.permissionNeededMessage,
      icon: Icons.info_outline,
      confirmLabel: t.continueLabel,
    );
  }

  static Future<bool?> showLocationPermissionDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.locationPermissionTitle,
      message: t.locationPermissionMessage,
      icon: Icons.location_on_outlined,
      confirmLabel: t.settings,
    );
  }

  // ==========================================
  // 4. DIÀLEGS AMB INPUT O ESTAT
  // ==========================================

  static Future<String?> askGpxFilename(
    BuildContext context,
    String suggestedName,
  ) async {
    final t = AppLocalizations.of(context)!;
    // Pre-omplim el controlador amb el nom suggerit i seleccionem el text
    final controller = TextEditingController(text: suggestedName);

    final bool? confirmed = await _showBaseDialog(
      context: context,
      title: t.exportTitle, // O la clau que tinguis per "Anomenar fitxer"
      message: "",
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.skyBlue,
      confirmLabel: t.export, // O t.save
      extraContent: [
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: t.waypointNameHint, // "Escriu el nom..."
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.skyBlue),
            ),
          ),
          // Selecciona tot el text automàticament per facilitar l'edició
          onTap: () => controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
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

  static void showElevationProgressDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(elevationProgressProvider);
          final hasError = state.error != null;
          return _showBaseDialog(
                context: context,
                title: hasError ? t.error : t.elevationFixing,
                message: hasError ? state.error! : "",
                confirmLabel: hasError ? t.close : null,
                extraContent: hasError
                    ? null
                    : [
                        LinearProgressIndicator(
                          value: state.progress,
                          color: AppColors.skyBlue,
                          backgroundColor: Colors.white10,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            "${(state.progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: AppColors.mustardYellow,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
              )
              as Widget;
        },
      ),
    );
  }

  // ==========================================
  // 5. SNACKBARS
  // ==========================================

  static void showSuccessSnackBar(BuildContext context, String message) =>
      _showCustomSnackBar(
        context,
        message: message,
        backgroundColor: Colors.green.shade700,
        icon: Icons.check_circle,
      );
  static void showErrorSnackBar(BuildContext context, String message) =>
      _showCustomSnackBar(
        context,
        message: message,
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

  static void showEndOfTrackSnackBar(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    _showCustomSnackBar(
      context,
      message: t.endOfTrack,
      backgroundColor: AppColors.skyBlue,
      icon: Icons.flag_rounded,
    );
  }

  static void showOffTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final t = AppLocalizations.of(context)!;
    _showCustomSnackBar(
      context,
      message: t.offTrack,
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
  }

  static void showBackOnTrackPersistentSnackbar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final t = AppLocalizations.of(context)!;
    _showCustomSnackBar(
      context,
      message: t.backOnTrack,
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

  static Future<String?> showStopRecordingDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: const Row(
          children: [
            Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Finalitzar gravació",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Què vols fer amb la gravació actual?",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, "share"),
                  child: const Icon(Icons.share, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, "finish"),
                  child: const Text(
                    "FINALITZAR",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteTrackDialog(BuildContext context) {
    return _showBaseDialog(
      context: context,
      title: "Eliminar dades?",
      message: "Vols eliminar la informació actual del track?",
      icon: Icons.delete_forever,
      iconColor: Colors.redAccent,
      confirmLabel: "ELIMINAR",
      cancelLabel: "MANTENIR",
      barrierDismissible: false,
    );
  }
}
