import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/alarm_progress.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/theme/app_colors.dart';

class AlarmSettingsTab extends ConsumerStatefulWidget {
  const AlarmSettingsTab({super.key});

  @override
  ConsumerState<AlarmSettingsTab> createState() => _AlarmSettingsTabState();
}

class _AlarmSettingsTabState extends ConsumerState<AlarmSettingsTab> {
  // ───────────────────────────────────────────────
  // FORMAT HELPERS
  // ───────────────────────────────────────────────

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
    final progress = ref.watch(alarmProgressProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.alarms, style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- DISTÀNCIA ---
          _buildAlarmCard(
            context: context,
            t: t,
            progress: progress,
            isActive: settings.distanceEnabled,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            valueText: _formatDistance(settings.distanceMeters),
            value: settings.distanceMeters,
            min: 100,
            max: 10000,
            divisions: 99,
            onChanged: (val) {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setDistanceAlarm(settings.distanceEnabled, val);
            },
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setDistanceAlarm(
                    !settings.distanceEnabled,
                    settings.distanceMeters,
                  );
            },
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playDistanceAlarm(),
          ),

          const SizedBox(height: 16),

          // --- ALTITUD ---
          _buildAlarmCard(
            context: context,
            t: t,
            progress: progress,
            isActive: settings.altitudeEnabled,
            icon: Icons.height,
            title: t.alarmsAltitudeTitle,
            valueText: "${settings.altitudeMeters.toInt()} m",
            value: settings.altitudeMeters,
            min: 0,
            max: 500,
            divisions: 50,
            onChanged: (val) {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeAlarm(settings.altitudeEnabled, val);
            },
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeAlarm(
                    !settings.altitudeEnabled,
                    settings.altitudeMeters,
                  );
            },
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playAltitudeAlarm(),
          ),

          const SizedBox(height: 16),

          // --- TEMPS ---
          _buildAlarmCard(
            context: context,
            t: t,
            progress: progress,
            isActive: settings.timeEnabled,
            icon: Icons.timer,
            title: t.alarmsTimeTitle,
            valueText: _formatTime(settings.timeSeconds),
            value: settings.timeSeconds.toDouble(),
            min: 60,
            max: 3600,
            divisions: 59,
            onChanged: (val) {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setTimeAlarm(settings.timeEnabled, val.round());
            },
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setTimeAlarm(!settings.timeEnabled, settings.timeSeconds);
            },
            onPlaySound: () =>
                ref.read(alarmEngineProvider).sounds.playTimeAlarm(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // TARGETA D’ALARMA (AMB EL CÀLCUL ANTIC)
  // ───────────────────────────────────────────────

  Widget _buildAlarmCard({
    required BuildContext context,
    required AppLocalizations t,
    required AlarmProgress? progress,
    required bool isActive,
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
    final step = (max - min) / divisions;
    final Color currentColor = isActive ? AppColors.primary : Colors.grey;

    // AQUESTA ÉS LA LÒGICA DEL CODI ANTIC QUE SÍ QUE FUNCIONA
    final double progressValue = progress == null
        ? 0.0
        : (title == t.alarmsDistanceTitle
              ? progress.distance
              : title == t.alarmsAltitudeTitle
              ? progress.altitude
              : progress.time);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive
              ? AppColors.primary.withAlpha(80)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: ICONA + PROGRÉS + TÍTOL + SWITCH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: progressValue.toDouble().clamp(0.0, 1.0),
                          strokeWidth: 3,
                          backgroundColor: Colors.grey.withAlpha(30),
                          color: currentColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(icon),
                        color: currentColor,
                        onPressed: onPlaySound,
                        iconSize: 22,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentColor,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: isActive,
                activeTrackColor: AppColors.primary,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 16),

          // CONTROLS: - [BURBULLA + SLIDER] +
          Row(
            children: [
              IconButton(
                onPressed: value > min
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged((value - step).clamp(min, max));
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 28),
                color: currentColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    // Burbulla estil GPS Settings
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        valueText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: currentColor,
                        inactiveTrackColor: Colors.grey.withAlpha(30),
                        trackHeight: 6,
                        thumbColor: currentColor,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        divisions: divisions,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          onChanged(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: value < max
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged((value + step).clamp(min, max));
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 28),
                color: currentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
