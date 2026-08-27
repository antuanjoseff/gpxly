import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/gps_debug_notifier.dart';
import 'package:strack_rec/notifiers/gps_settings_notifier.dart';
import 'package:strack_rec/notifiers/alarm_settings_notifier.dart';
import 'package:strack_rec/services/altitude_logger.dart';
import 'package:strack_rec/theme/app_colors.dart';

class GpsSettingsTab extends ConsumerWidget {
  const GpsSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gps = ref.watch(gpsSettingsProvider);
    final isFollowing = gps.isFollowing;
    final alarms = ref.watch(alarmSettingsProvider);
    final isAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;
    final t = AppLocalizations.of(context)!;

    // Definim l'estat d'activació global de la secció d'autonconfiguració
    final bool canEdit = !isFollowing && !isAlarmActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.gpsTab,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner d'informació corporativa
          _buildInfoBanner(t.gpsAutoConfigInfo),
          const SizedBox(height: 16),

          Text(
            t.gpsRecordingMethod,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          // ⏱️ 1. FILA TEMPS
          _buildGpsRowSetting(
            context: context,
            isActive: canEdit && gps.useTime,
            title: t.gpsRecordByTime,
            valueText: "${gps.seconds} s",
            value: gps.seconds.toDouble(),
            min: 2,
            max: 60,
            step: 1,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setSeconds(val.toInt());
              ref.read(gpsSettingsProvider.notifier).setUseTime(true);
            },
            onChangeEnd: (val) =>
                ref.read(gpsSettingsProvider.notifier).apply(),
            onToggle: () {
              ref.read(gpsSettingsProvider.notifier).setUseTime(true);
              ref.read(gpsSettingsProvider.notifier).apply();
            },
          ),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),

          // 📏 2. FILA DISTÀNCIA
          _buildGpsRowSetting(
            context: context,
            isActive: canEdit && !gps.useTime,
            title: t.gpsRecordByDistance,
            valueText: "${gps.meters.toInt()} m",
            value: gps.meters.toDouble(),
            min: 5,
            max: 100,
            step: 1,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setMeters(val);
              ref.read(gpsSettingsProvider.notifier).setUseTime(false);
            },
            onChangeEnd: (val) =>
                ref.read(gpsSettingsProvider.notifier).apply(),
            onToggle: () {
              ref.read(gpsSettingsProvider.notifier).setUseTime(false);
              ref.read(gpsSettingsProvider.notifier).apply();
            },
          ),

          const SizedBox(height: 16),
          Text(
            t.gpsSignalQuality,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // 🎯 3. FILA PRECISIÓ MÀXIMA
          _buildGpsRowSetting(
            context: context,
            isActive: canEdit,
            title: t.gpsMaxAccuracy,
            valueText: "${gps.accuracy.toInt()} m",
            value: gps.accuracy,
            min: 5,
            max: 100,
            step: 5,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setAccuracy(val);
            },
            onChangeEnd: (val) =>
                ref.read(gpsSettingsProvider.notifier).apply(),
            onToggle: null,
            hideSwitch: true, // Amaguem el switch mecànic per a la precisió
          ),
          const SizedBox(height: 12),

          // Mode diagnòstic per a desenvolupadors (Debug Mode)
          if (kDebugMode)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: SwitchListTile.adaptive(
                title: Text(
                  t.gpsDiagnosticMode,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(t.gpsDiagnosticDescription),
                value: ref.watch(gpsDebugProvider),
                onChanged: (value) async {
                  await ref.read(gpsDebugProvider.notifier).setEnabled(value);
                  await AltitudeLoggerService().setDebugEnabled(value);
                  await ref.read(gpsSettingsProvider.notifier).apply();
                },
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Giny unificat en dues línies amb el Switch mecànic i Slider optimitzat
  Widget _buildGpsRowSetting({
    required BuildContext context,
    required bool isActive,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required VoidCallback? onToggle,
    bool hideSwitch = false,
  }) {
    final color = isActive ? AppColors.primary : Colors.grey.shade400;
    final divisions = ((max - min) / step).round();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── LÍNIA 1: TÍTOL, MÈTRICA I SWITCH TEXTUAL ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valueText,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
                if (!hideSwitch) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onToggle != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onToggle();
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      height: 28,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withAlpha(40)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 6,
                            child: Text(
                              "ON",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            child: Text(
                              "OFF",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: !isActive
                                    ? Colors.grey.shade600
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: isActive
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.grey.shade500,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // ─── LÍNIA 2: RECORREGUT DEL SLIDER AMB CONTROLS ───
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: color,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: isActive && value > min
                      ? () {
                          HapticFeedback.lightImpact();
                          final newVal = (value - step).clamp(min, max);
                          onChanged(newVal);
                          onChangeEnd(newVal);
                        }
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: value.clamp(min, max),
                      min: min,
                      max: max,
                      divisions: divisions > 0 ? divisions : null,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withAlpha(30),
                      onChanged: isActive ? onChanged : null,
                      onChangeEnd: isActive ? onChangeEnd : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: color,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: isActive && value < max
                      ? () {
                          HapticFeedback.lightImpact();
                          final newVal = (value + step).clamp(min, max);
                          onChanged(newVal);
                          onChangeEnd(newVal);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
