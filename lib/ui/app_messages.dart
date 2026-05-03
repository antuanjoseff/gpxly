import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/models/waypoint.dart';
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
    elevation: 0, // Més modern, sense ombra pesada
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
    Color? confirmColor, // Per a botons vermells/alerta
    String? cancelLabel,
    bool barrierDismissible = true,
    List<Widget>? extraContent,
  }) {
    final t = AppLocalizations.of(context)!;

    // Configuració de colors per evitar que el disseny es vegi "pesat"
    const Color surfaceColor = Color(
      0xFF242426,
    ); // Gris fosc suau (estil sistema)
    final Color accentColor = confirmColor ?? AppColors.skyBlue;
    final Color secondaryText = Colors.white.withAlpha(
      170,
    ); // Blanc trencat per no fatigar

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent, // Imprescindible en Material 3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Vora fina per donar definició sense carregar
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  letterSpacing: -0.4,
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
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            if (extraContent != null) ...[
              // Espaiat dinàmic segons si hi ha missatge o no
              SizedBox(height: message.isNotEmpty ? 20 : 8),
              ...extraContent,
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (cancelLabel != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      color: Colors.white.withAlpha(130),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel ?? t.ok,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
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

    final controller = TextEditingController(text: suggestedName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: suggestedName.length,
      );

    final bool? confirmed = await _showBaseDialog(
      context: context,
      title: t.gpxFilenameTitle,
      message: "",
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.skyBlue,
      confirmLabel: t.export,
      extraContent: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: t.gpxFilenameLabel,
              labelStyle: const TextStyle(color: AppColors.skyBlue),
              hintText: t.gpxFilenameHint,
              hintStyle: const TextStyle(color: Colors.white30),
              suffixText: '.gpx',
              suffixStyle: const TextStyle(color: Colors.white54),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppColors.skyBlue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              // Substituït withOpacity(0.05) per withAlpha
              // Si uses Flutter 3.22+, withAlpha rep un double (0.0 a 1.0)
              // Si uses una versió anterior, seria .withAlpha(13) (5% de 255)
              fillColor: Colors.white.withAlpha((255 * 0.05).round()),
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
    final t = AppLocalizations.of(context)!;
    const Color surfaceColor = Color(0xFF242426);

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.stop_circle_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  t.finishRecordingTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, null),
              icon: Icon(Icons.close, color: Colors.white.withAlpha(100)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.finishRecordingMessage,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "finish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                t.finishRecordingConfirm,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, "share"),
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(t.shareTrack),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(30),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
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
        actions: const [],
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

  static Future<bool?> showDeleteImportedTrackDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return _showBaseDialog(
      context: context,
      title: t.deleteTrackTitle,
      message: t.deleteTrackMessage,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
      confirmLabel: t.deleteTrackConfirm,
      confirmColor: Colors.redAccent,
      cancelLabel: t.cancel, // Ja la tenies al diccionari
      barrierDismissible: true,
    );
  }

  static Future<void> showWaypointDetails(
    BuildContext context,
    Waypoint wp,
    Duration? elapsed,
  ) {
    final t = AppLocalizations.of(context)!;
    const Color surfaceColor = Color(0xFF242426);
    final Color secondaryText = Colors.white.withAlpha(170);
    // Formatem la durada (ex: 01:24:05)

    String? formattedDuration;
    if (elapsed != null) {
      final hours = elapsed.inHours.toString().padLeft(2, '0');
      final minutes = elapsed.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = elapsed.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      formattedDuration = "$hours:$minutes:$seconds";
    }
    // Formatem la distància si existeix
    final String? formattedDistance = wp.distanceAtPoint != null
        ? "${(wp.distanceAtPoint! / 1000).toStringAsFixed(2)} km"
        : null;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: Row(
          children: [
            const Icon(Icons.place_rounded, color: AppColors.skyBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.waypointDetailsTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                color: Colors.white.withAlpha(100),
                size: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailItem(
              t.waypointName,
              wp.name,
              Icons.label_outline,
              secondaryText,
            ),
            _buildDetailItem(
              t.waypointAltitude,
              "${wp.ele?.toStringAsFixed(0) ?? '---'} m",
              Icons.height,
              secondaryText,
            ),
            _buildDetailItem(
              t.waypointTrackPoint,
              "#${wp.trackIndex}",
              Icons.timeline,
              secondaryText,
            ),
            // Mostrem la distància només si s'ha calculat prèviament
            if (formattedDistance != null)
              _buildDetailItem(
                t.waypointDistance,
                formattedDistance,
                Icons.route_outlined,
                secondaryText,
              ),
            if (formattedDuration != null)
              _buildDetailItem(
                t.waypointTime,
                formattedDuration,
                Icons.timer_outlined,
                secondaryText,
              ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(30),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(t.ok),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color labelColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Manté l'icona a dalt si el text creix
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 12),

          // El label ara ocupa tot l'espai central i fa wrap si cal
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 14),
              softWrap: true, // Permet el salt de línia
            ),
          ),

          const SizedBox(width: 12), // Espai de separació
          // El valor es manté a la dreta, fix, sense moure's
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showGpsOptimizationDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _showBaseDialog(
      context: context,
      title: t.gpsOptimizationTitle,
      message: t.gpsOptimizationMessage,
      icon: Icons.bolt_rounded,
      iconColor: Colors.amberAccent,
      confirmLabel: t.confirm, // O t.activate segons el teu .arb
      cancelLabel: t.cancel,
    );
  }

  static Future<bool?> showPendingChangesDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return _showBaseDialog(
      context: context,
      barrierDismissible: false,
      title: t.pendingChangesTitle,
      message: t.pendingChangesMessage,
      icon: Icons.info_outline,
      iconColor: AppColors.skyBlue,
      confirmLabel: t.apply,
      cancelLabel: t.discard,
    );
  }
}
