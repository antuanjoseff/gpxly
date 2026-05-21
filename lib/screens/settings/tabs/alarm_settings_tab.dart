import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Per al feedback hàptic
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/theme/app_colors.dart';

class AlarmSettingsTab extends ConsumerStatefulWidget {
  const AlarmSettingsTab({super.key});

  @override
  ConsumerState<AlarmSettingsTab> createState() => _AlarmSettingsTabState();
}

class _AlarmSettingsTabState extends ConsumerState<AlarmSettingsTab> {
  // Helpers de format (mantenim els teus)
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
    return "$h h ${m} min";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final settings = ref.watch(alarmSettingsProvider);
    // Recuperem el progrés en temps real
    final progress = ref.watch(alarmProgressProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
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
          _buildCompactAlarmCard(
            isActive: settings.distanceEnabled,
            progressValue: (progress != null && settings.distanceEnabled)
                ? progress.distance
                : 0.0,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            valueText: _formatDistance(settings.distanceMeters),
            value: settings.distanceMeters,
            min: 100,
            max: 10000,
            divisions: 99,
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
          _buildCompactAlarmCard(
            isActive: settings.altitudeEnabled,
            progressValue: (progress != null && settings.altitudeEnabled)
                ? progress.altitude
                : 0.0,
            icon: Icons.height,
            title: t.alarmsAltitudeTitle,
            valueText: "${settings.altitudeMeters.toInt()} m",
            value: settings.altitudeMeters,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (val) => ref
                .read(alarmSettingsProvider.notifier)
                .setAltitudeAlarm(settings.altitudeEnabled, val),
            onToggle: () => _handleToggle(
              () => ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeAlarm(
                    !settings.altitudeEnabled,
                    settings.altitudeMeters,
                  ),
            ),
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playAltitudeAlarm(),
          ),
          const SizedBox(height: 16),
          _buildCompactAlarmCard(
            isActive: settings.timeEnabled,
            progressValue: (progress != null && settings.timeEnabled)
                ? progress.time
                : 0.0,
            icon: Icons.timer,
            title: t.alarmsTimeTitle,
            valueText: _formatTime(settings.timeSeconds),
            value: settings.timeSeconds.toDouble(),
            min: 60,
            max: 3600,
            divisions: 59,
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

  Future<void> _handleToggle(VoidCallback action) async {
    if (await PermissionsService.ensurePermissions(context)) {
      HapticFeedback.mediumImpact(); // Afegim feedback físic
      action();
    }
  }

  Widget _buildCompactAlarmCard({
    required bool isActive,
    required double progressValue,
    required IconData icon,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required VoidCallback onToggle,
    required VoidCallback onPlaySound,
  }) {
    final currentColor = isActive ? AppColors.primary : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(80)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Recuperem l'indicador circular de progrés amb el botó de so
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progressValue.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.withAlpha(30),
                      color: currentColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(icon, size: 20),
                    color: currentColor,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onPlaySound();
                    },
                  ),
                ],
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
                activeColor: AppColors.primary,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildSliderRow(value, min, max, divisions, onChanged, isActive),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
    bool isActive,
  ) {
    final step = (max - min) / divisions;
    return Row(
      children: [
        IconButton(
          onPressed: value > min
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged((value - step).clamp(min, max));
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: isActive ? AppColors.primary : Colors.grey,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isActive
                  ? AppColors.primary
                  : Colors.grey.shade300,
              thumbColor: isActive ? AppColors.primary : Colors.grey.shade400,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (val) {
                if ((val - value).abs() > step / 2)
                  HapticFeedback.selectionClick();
                onChanged(val);
              },
            ),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged((value + step).clamp(min, max));
                }
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: isActive ? AppColors.primary : Colors.grey,
        ),
      ],
    );
  }
}
