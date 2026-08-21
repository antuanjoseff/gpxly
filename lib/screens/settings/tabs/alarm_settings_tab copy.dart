import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/alarm_settings_notifier.dart';
import 'package:strack_rec/services/permissions_service.dart';
import 'package:strack_rec/theme/app_colors.dart';

class AlarmSettingsTab extends ConsumerStatefulWidget {
  const AlarmSettingsTab({super.key});

  @override
  ConsumerState<AlarmSettingsTab> createState() => _AlarmSettingsTabState();
}

class _AlarmSettingsTabState extends ConsumerState<AlarmSettingsTab> {
  String _formatDistance(double m) {
    if (m < 1000) return "${m.toInt()} m";
    return "${(m / 1000).toStringAsFixed(1)} km";
  }

  String _formatTime(int s) {
    if (s < 60) return "$s s";
    if (s < 3600) return "${(s / 60).round()} min";
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (m == 0) return "$h h";
    return "$h h $m min";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final settings = ref.watch(alarmSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F7,
      ), // Fons clar de la configuració de STrack Rec
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Fletxa de retorn blanca pura
        title: Text(
          t.alarms,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 📊 1. TARGETA DE DISTÀNCIA
          _buildCompactAlarmCard(
            isActive: settings.distanceEnabled,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            valueText: _formatDistance(settings.distanceMeters),
            value: settings.distanceMeters,
            min: 100,
            max: 5000,
            step: 100,
            onChanged: (val) => ref
                .read(alarmSettingsProvider.notifier)
                .setDistanceAlarm(settings.distanceEnabled, val),
            onToggle: () => _handleToggle(
              () => ref
                  .read(alarmSettingsProvider.notifier)
                  .setDistanceAlarm(
                    !settings.distanceEnabled,
                    settings.distanceMeters,
                  ),
            ),
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playDistanceAlarm(),
          ),
          const SizedBox(height: 16),

          // 📊 2. TARGETA D'ALTITUD INTEGRADA (Cotes / Desnivell)
          _buildAltitudeIntegratedCard(settings, t),

          const SizedBox(height: 16),

          // 📊 3. TARGETA DE TEMPS
          _buildCompactAlarmCard(
            isActive: settings.timeEnabled,
            icon: Icons.timer,
            title: t.alarmsTimeTitle,
            valueText: _formatTime(settings.timeSeconds),
            value: settings.timeSeconds.toDouble(),
            min: 60,
            max: 3600,
            step: 60,
            onChanged: (val) => ref
                .read(alarmSettingsProvider.notifier)
                .setTimeAlarm(settings.timeEnabled, val.round()),
            onToggle: () => _handleToggle(
              () => ref
                  .read(alarmSettingsProvider.notifier)
                  .setTimeAlarm(!settings.timeEnabled, settings.timeSeconds),
            ),
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playTimeAlarm(),
          ),
        ],
      ),
    );
  }

  Widget _buildAltitudeIntegratedCard(dynamic settings, AppLocalizations t) {
    final isAccMode = settings.currentViewMode == AltitudeViewMode.accumulated;

    final isCurrentModeActive = isAccMode
        ? settings.accEnabled
        : settings.cotaEnabled;

    final valueText = isAccMode
        ? "+ ${settings.accMeters.toInt()} m"
        : t.alarmsCotaValue(settings.cotaMeters.toInt());

    // 🟢 DISSENY REFACTORITZAT: Vores fines clares, la línia de contorn ara utilitza fons fi en lloc de 2px forts
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentModeActive
              ? AppColors.primary.withAlpha(40) // Contorn suau corporatiu
              : Colors.white.withAlpha(30),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final progress = ref.watch(alarmProgressProvider).value;
                  final progressValue = isAccMode
                      ? (progress?.accProgress ?? 0.0)
                      : (progress?.cotaProgress ?? 0.0);

                  return _buildProgressIcon(
                    isCurrentModeActive,
                    progressValue,
                    isAccMode ? Icons.trending_up : Icons.layers,
                    () {
                      if (isAccMode) {
                        ref
                            .read(alarmEngineProvider)
                            .sounds
                            .playAccumulatedAlarm();
                      } else {
                        ref.read(alarmEngineProvider).sounds.playCotaAlarm();
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                t.alarmsAltitudeTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: isCurrentModeActive,
                onChanged: (_) => _handleToggle(() {
                  if (isAccMode) {
                    ref
                        .read(alarmSettingsProvider.notifier)
                        .setAccAlarm(!settings.accEnabled, settings.accMeters);
                  } else {
                    ref
                        .read(alarmSettingsProvider.notifier)
                        .setCotaAlarm(
                          !settings.cotaEnabled,
                          settings.cotaMeters,
                        );
                  }
                }),
                activeTrackColor: AppColors.primary.withAlpha(150),
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<AltitudeViewMode>(
            segments: [
              ButtonSegment(
                value: AltitudeViewMode.accumulated,
                label: Text(t.alarmsAccSegmentLabel),
                icon: settings.accEnabled
                    ? const Icon(Icons.check_circle, size: 14)
                    : const Icon(Icons.show_chart, size: 16),
              ),
              ButtonSegment(
                value: AltitudeViewMode.absolute,
                label: Text(t.alarmsCotaSegmentLabel),
                icon: settings.cotaEnabled
                    ? const Icon(Icons.check_circle, size: 14)
                    : const Icon(Icons.straighten, size: 16),
              ),
            ],
            selected: {settings.currentViewMode},
            onSelectionChanged: (newSelection) {
              HapticFeedback.selectionClick();
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeViewMode(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderSection(
            isActive: isCurrentModeActive,
            valueText: valueText,
            value: isAccMode ? settings.accMeters : settings.cotaMeters,
            min: isAccMode ? 10.0 : 50.0,
            max: isAccMode ? 1000.0 : 1000.0,
            step: isAccMode ? 10.0 : 50.0,
            onChanged: (val) {
              if (isAccMode) {
                ref
                    .read(alarmSettingsProvider.notifier)
                    .setAccAlarm(settings.accEnabled, val);
              } else {
                ref
                    .read(alarmSettingsProvider.notifier)
                    .setCotaAlarm(settings.cotaEnabled, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIcon(
    bool isActive,
    double progress,
    IconData icon,
    VoidCallback onTap,
  ) {
    final color = isActive ? AppColors.primary : Colors.grey;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: Colors.grey.withAlpha(30),
            color: color,
          ),
        ),
        IconButton(icon: Icon(icon, size: 20), color: color, onPressed: onTap),
      ],
    );
  }

  Widget _buildSliderSection({
    required bool isActive,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required double step,
  }) {
    final buttonColor = isActive ? AppColors.primary : Colors.grey.shade400;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            valueText,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: buttonColor,
              onPressed: isActive && value > min
                  ? () {
                      HapticFeedback.lightImpact();
                      final newVal = (value - step).clamp(min, max);
                      onChanged(newVal);
                    }
                  : null,
            ),
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: ((max - min) / step).round(),
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withAlpha(30),
                onChanged: isActive ? onChanged : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: buttonColor,
              onPressed: isActive && value < max
                  ? () {
                      HapticFeedback.lightImpact();
                      final newVal = (value + step).clamp(min, max);
                      onChanged(newVal);
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactAlarmCard({
    required bool isActive,
    required IconData icon,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required VoidCallback onToggle,
    required VoidCallback onPlaySound,
    required double step,
  }) {
    // 🟢 REFACTORITZAT: Unificació de línia fina i ombres integrades
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(40)
              : Colors.white.withAlpha(30),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final progress = ref.watch(alarmProgressProvider).value;
                  double pVal = 0.0;
                  if (isActive && progress != null) {
                    if (icon == Icons.route) pVal = progress.distance;
                    if (icon == Icons.timer) pVal = progress.time;
                  }

                  return _buildProgressIcon(isActive, pVal, icon, onPlaySound);
                },
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : Colors.black87,
                ),
              ),
              const Spacer(),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeTrackColor: AppColors.primary.withAlpha(150),
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSliderSection(
            isActive: isActive,
            valueText: valueText,
            value: value,
            min: min,
            max: max,
            step: step,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(VoidCallback action) async {
    if (await PermissionsService.ensurePermissions(context)) {
      HapticFeedback.mediumImpact();
      action();
    }
  }
}
