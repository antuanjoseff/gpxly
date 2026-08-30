import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_recorded_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';

class AppMessages {
  // ==========================================
  // 1. ESTILS I COLORS (Estètica de l'App)
  // ==========================================

  static final Color _surfaceColor = const Color(0xFF556B2F).withAlpha(20);
  static const Color _secondaryText = Color(0xFFFFFFFF);

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
    List<Widget>? actions, // ✅ NOU PARÀMETRE OPTIONAL
  }) {
    final t = AppLocalizations.of(context)!;
    final Color accentColor = confirmColor ?? AppColors.skyBlue;

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.skyBlueDark,
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
                  color: AppColors.offWhite,
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
                    color: AppColors.offWhite.withAlpha(220),
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
        // ✅ ADAPTAT: Si li passem botons customitzats, els pinta directament en horitzontal
        actions:
            actions ??
            [
              if (cancelLabel != null || confirmLabel != null)
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
                    if (confirmLabel != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: _buttonStyle(accentColor),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(confirmLabel),
                      ),
                    ],
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
        title: AppLocalizations.of(context)!.gpsDisabled,
        message: '',
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
        cancelLabel: AppLocalizations.of(context)!.cancel,
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
  static Future<bool?> showBatteryOptimizationDialog(BuildContext context) =>
      _showBaseDialog(
        context: context,
        title: AppLocalizations.of(context)!.batteryOptimizationTitle,
        message: AppLocalizations.of(context)!.batteryOptimizationMessage,
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
        title: AppLocalizations.of(context)!.deleteCurrentTrackTitle,
        message: AppLocalizations.of(context)!.deleteCurrentTrackMessage,
        icon: Icons.delete_forever,
        iconColor: Colors.redAccent,
        confirmLabel: AppLocalizations.of(context)!.deleteConfirm,
        confirmColor: Colors.redAccent,
        cancelLabel: AppLocalizations.of(context)!.deleteCurrentTrackKeep,
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
    WidgetRef ref,
    Waypoint wp,
    Duration? elapsed,
  ) {
    final t = AppLocalizations.of(context)!;

    String? formattedDuration;
    if (elapsed != null) {
      formattedDuration =
          "${elapsed.inHours.toString().padLeft(2, '0')}:${elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }

    final bool isDeletable = wp.id.startsWith('rec_');
    final nameKey = GlobalKey<_EditableWaypointNameState>();

    return _showBaseDialog(
      context: context,
      title: t.waypointDetailsTitle,
      message: "",
      icon: Icons.place_rounded,
      iconColor: AppColors.skyBlue,
      confirmLabel:
          null, // 🎯 ANUL·LEM el botó automàtic per defecte que es trencava
      extraContent: [
        _EditableWaypointName(
          key: nameKey,
          wp: wp,
          ref: ref,
          label: t.waypointName,
        ),
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
      // ─────────────────────────────────────────────────────────────
      // 🔥 LA SOLUCIÓ: BOTONS FORÇATS A LA MATEIXA FILA HORITZONTAL
      // ─────────────────────────────────────────────────────────────
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // 1. Botó d'Eliminar (A l'esquerra de tot)
              if (isDeletable)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    t.deleteConfirm.toUpperCase(), // Farà servir "ELIMINAR"
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Tanquem detalls

                    final confirm = await _showBaseDialog(
                      context: context,
                      title: t.deleteWaypointTitle,
                      message: t.deleteWaypointMessage,
                      icon: Icons.delete_forever,
                      iconColor: Colors.redAccent,
                      confirmLabel: t.deleteConfirm,
                      confirmColor: Colors.redAccent,
                      cancelLabel: t.cancel,
                    );

                    if (confirm == true) {
                      if (!context.mounted) return;
                      ref.read(waypointsProvider.notifier).remove(wp.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Expanded(child: Text(t.waypointDeletedSuccess)),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                                onPressed: () => ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar(),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green.shade800,
                        ),
                      );
                    }
                  },
                )
              else
                const SizedBox.shrink(),

              const Spacer(), // Empeny de forma automàtica el següent botó cap a la dreta
              // 2. Botó d'Acceptar (A la dreta de tot)
              ElevatedButton(
                style: _buttonStyle(AppColors.skyBlue),
                onPressed: () {
                  nameKey.currentState?.saveIfEditing();
                  Navigator.pop(context, true);
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
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

    String? result;

    await _showBaseDialog(
      context: context,
      title: t.finishRecordingTitle,
      message: t.finishRecordingMessage,
      icon: Icons.stop_circle_rounded,
      iconColor: Colors.redAccent,
      confirmLabel: null, // No fem servir el botó OK estàndard
      cancelLabel: null, // Tampoc el cancel·la estàndard
      extraContent: [
        const SizedBox(height: 20),

        // SHARE
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              result = "share";
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.share_rounded, size: 20),
            label: Text(
              t.shareTrack,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: _buttonStyle(const Color(0xFF2E7D32)),
          ),
        ),

        const SizedBox(height: 12),

        // FINISH
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              result = "finish";
              Navigator.pop(context, true);
            },
            style: _buttonStyle(
              Colors.redAccent,
            ).copyWith(foregroundColor: WidgetStateProperty.all(Colors.white)),

            child: Text(
              t.finishRecordingConfirm,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // CONTINUE
        Center(
          child: TextButton(
            onPressed: () {
              result = null;
              Navigator.pop(context, true);
            },
            child: Text(
              t.continueRecording,
              style: TextStyle(color: Colors.white.withAlpha(120)),
            ),
          ),
        ),
      ],
    );

    return result;
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
            labelStyle: const TextStyle(color: AppColors.skyBlue),
            enabledBorder: const UnderlineInputBorder(
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
      confirmLabel: AppLocalizations.of(context)!.ok,
      cancelLabel: AppLocalizations.of(context)!.cancel,
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
            trailing ??
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
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

  static void showActiveSessionExitWarning(
    BuildContext context, {
    required bool isRecording,
    required bool isFollowing,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final message = isRecording && isFollowing
        ? localizations.exitWhileRecordingAndFollowing
        : isRecording
        ? localizations.exitWhileRecording
        : localizations.exitWhileFollowing;
    _showCustomSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade800,
      icon: Icons.warning_amber_rounded,
    );
  }

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
        // ✅ ADAPTAT: Tanca l'alerta usant el nou navigationProvider
        ref.read(navigationProvider.notifier).clearOffTrackSnackbar();
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
        // ✅ ADAPTAT: Tanca l'alerta usant el nou navigationProvider
        ref.read(navigationProvider.notifier).dismissBackOnTrackAlert();
      },
    ),
  );

  static void showWaypointPersistentSnackbar(
    BuildContext context,
    WidgetRef ref, {
    required String waypointName,
    required double distanceMeters,
  }) => _showCustomSnackBar(
    context,
    message:
        'A ${distanceMeters.toStringAsFixed(0)} m del waypoint: $waypointName',
    backgroundColor: Colors.green.shade700,
    icon: Icons.place,
    duration: const Duration(days: 1),
    trailing: IconButton(
      icon: const Icon(Icons.close, color: Colors.white),
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ref.read(navigationProvider.notifier).clearWaypointSnackbar();
      },
    ),
  );

  /// Diàleg de control de gravació adaptat al mètode mestre Future<bool?>
  static Future<String?> showRecordingControlDialog({
    required BuildContext context,
    required RecordingState state,
  }) async {
    final t = AppLocalizations.of(context)!;
    String? selectedAction; // Variable temporal per desar l'acció

    String message = t.noRecordedTrack;
    if (state == RecordingState.recording) message = "${t.recording}...";
    if (state == RecordingState.paused) message = "${t.paused}...";

    // Invoquem el mètode mestre original passant els botons apilats en columna
    await _showBaseDialog(
      context: context,
      title: t.recordingTitle,
      message: message,
      icon: Icons.fiber_manual_record,
      iconColor: Colors.redAccent,
      confirmLabel: null, // No fem servir els botons estàndard de la base
      cancelLabel: null,
      extraContent: [
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Estira els botons per tenir la mateixa mida horitzontal
          children: [
            if (state == RecordingState.idle)
              ElevatedButton.icon(
                style: _buttonStyle(Colors.green),
                onPressed: () {
                  selectedAction = "start";
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(t.startRecording.toUpperCase()),
              ),
            if (state == RecordingState.recording)
              ElevatedButton.icon(
                style: _buttonStyle(Colors.orange),
                onPressed: () {
                  selectedAction = "pause";
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.pause, color: Colors.white),
                label: Text(t.pause.toUpperCase()),
              ),
            if (state == RecordingState.paused)
              ElevatedButton.icon(
                style: _buttonStyle(Colors.green),
                onPressed: () {
                  selectedAction = "resume";
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(t.resume.toUpperCase()),
              ),
            if (state == RecordingState.recording ||
                state == RecordingState.paused) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: _buttonStyle(Colors.red),
                onPressed: () {
                  selectedAction = "stop";
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.stop, color: Colors.white),
                label: Text(t.stopShort.toUpperCase()),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Tanca amb false
              child: Text(
                t.close.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withAlpha(130),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return selectedAction; // Retornem el String a map_screen
  }

  /// 🧭 DIÀLEG A: Control previ al seguiment (S'obre quan hi ha track però no s'està seguint)
  static Future<String?> showPreNavigationDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    String? selectedAction;

    await _showBaseDialog(
      context: context,
      title: t.importedTrack.toUpperCase(),
      message: t.importedTrack,
      icon: Icons.navigation_rounded,
      iconColor: AppColors.deepGreen,
      confirmLabel: null, // Netejem els botons natius horitzontals
      cancelLabel: null,
      extraContent: [
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: _buttonStyle(AppColors.deepGreen),
              onPressed: () {
                selectedAction = "follow"; // Acció per iniciar la navegació
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(t.followShort.toUpperCase()),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: _buttonStyle(Colors.redAccent),
              onPressed: () {
                selectedAction =
                    "clear_imported"; // Acció per esborrar el track del mapa
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: Text(t.discard.toUpperCase()),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                t.close.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withAlpha(130),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return selectedAction;
  }

  /// ⏸️ DIÀLEG B: Control de la navegació activa (S'obre quan la ruta està en curs)
  static Future<String?> showActiveNavigationDialog({
    required BuildContext context,
    required bool isFollowPaused,
  }) async {
    final t = AppLocalizations.of(context)!;
    String? selectedAction;

    await _showBaseDialog(
      context: context,
      title: t.followingTitle,
      message: isFollowPaused ? "${t.followPaused}..." : "${t.following}...",
      icon: isFollowPaused
          ? Icons.play_circle_outline
          : Icons.pause_circle_outline,
      iconColor: Colors.orange,
      confirmLabel: null, // Netejem els botons natius horitzontals
      cancelLabel: null,
      extraContent: [
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: _buttonStyle(Colors.orange),
              onPressed: () {
                selectedAction = "toggle_pause"; // Acció per pausar o reprendre
                Navigator.pop(context, true);
              },
              icon: Icon(
                isFollowPaused ? Icons.play_arrow_rounded : Icons.pause,
                color: Colors.white,
              ),
              label: Text(
                isFollowPaused ? t.resume.toUpperCase() : t.pause.toUpperCase(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: _buttonStyle(Colors.red),
              onPressed: () {
                selectedAction =
                    "stop_follow"; // Acció per parar la navegació i esborrar el track
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.stop, color: Colors.white),
              label: Text(t.stopShort.toUpperCase()),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                t.close.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withAlpha(130),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return selectedAction;
  }
}

/// Nom del waypoint amb edició inline: mostra el text i, en tocar l'icona de
/// llapis, el converteix en un camp editable que desa el canvi al notifier corresponent.
class _EditableWaypointName extends StatefulWidget {
  final Waypoint wp;
  final WidgetRef ref;
  final String label;

  const _EditableWaypointName({
    super.key,
    required this.wp,
    required this.ref,
    required this.label,
  });

  @override
  State<_EditableWaypointName> createState() => _EditableWaypointNameState();
}

class _EditableWaypointNameState extends State<_EditableWaypointName> {
  bool _isEditing = false;
  late String _displayName = widget.wp.name;
  late final TextEditingController _controller = TextEditingController(
    text: widget.wp.name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Desa el nom només si l'usuari estava editant (cridat des del botó OK del diàleg).
  void saveIfEditing() {
    if (_isEditing) _save();
  }

  void _save() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty && newName != widget.wp.name) {
      if (widget.wp.id.startsWith('rec_')) {
        widget.ref
            .read(waypointsProvider.notifier)
            .rename(widget.wp.id, newName);
      } else {
        widget.ref
            .read(importedWaypointsProvider.notifier)
            .rename(widget.wp.id, newName);
      }
    }
    setState(() {
      _isEditing = false;
      _displayName = newName.isNotEmpty ? newName : widget.wp.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.label_outline,
            size: 20,
            color: AppColors.skyBlue.withAlpha(180),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        onSubmitted: (_) => _save(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(),
                        ),
                      )
                    : Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        softWrap: true,
                      ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              size: 18,
              color: Colors.white.withAlpha(180),
            ),
            onPressed: () {
              if (_isEditing) {
                _save();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
    );
  }
}
