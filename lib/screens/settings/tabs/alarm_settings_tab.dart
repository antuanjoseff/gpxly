import 'package:flutter/material.dart';
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
  String _formatDistance(double m) {
    if (m < 1000) return "${m.toInt()} m";
    return "${(m / 1000).toStringAsFixed(1)} km";
  }

  String _formatTime(int s) {
    if (s < 60) return "$s s";
    if (s < 3600) return "${(s / 60).round()} min";
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return m == 0 ? "$h h" : "$h h ${m} min";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final settings = ref.watch(alarmSettingsProvider);
    final progress = ref.watch(alarmProgressProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(backgroundColor: AppColors.primary, title: Text(t.alarms)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  .setDistanceAlarm(true, val);
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

          const SizedBox(height: 24),

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
                  .setAltitudeAlarm(true, val);
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

          const SizedBox(height: 24),

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
                  .setTimeAlarm(true, val.round());
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

  // 🔊 BOTÓ DE SPEAKER AMB PROGRÉS INTEGRAT
  Widget _buildSpeakerButton({
    required bool isActive,
    required double progressValue,
    required VoidCallback onPressed,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive)
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 3,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.volume_up),
          color: AppColors.primary,
          onPressed: onPressed,
          iconSize: 28,
        ),
      ],
    );
  }

  // 🟦 TARGETA D’ALARMA (OPCIÓ 4)
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
    final progressValue = progress == null
        ? 0
        : (title == t.alarmsDistanceTitle
              ? progress.distance
              : title == t.alarmsAltitudeTitle
              ? progress.altitude
              : progress.time);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
          // ─────────────────────────────
          // PRIMERA LÍNIA
          // ─────────────────────────────
          Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),

              // Speaker + progress
              _buildSpeakerButton(
                isActive: isActive,
                progressValue: progressValue.toDouble(),
                onPressed: onPlaySound,
              ),

              const SizedBox(width: 8),

              // Switch petit i amb color dinàmic
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  thumbColor: WidgetStateProperty.all(
                    isActive ? AppColors.primary : Colors.grey,
                  ),
                  trackColor: WidgetStateProperty.all(
                    isActive
                        ? AppColors.primary.withAlpha(120)
                        : Colors.grey.withAlpha(80),
                  ),
                  onChanged: (_) => onToggle(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ─────────────────────────────
          // VALOR CENTRAT
          // ─────────────────────────────
          Center(
            child: Text(
              valueText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ─────────────────────────────
          // SLIDER + BOTONS
          // ─────────────────────────────
          _buildCompactSliderRow(
            context: context,
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            isActive: isActive,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSliderRow({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required bool isActive,
    required ValueChanged<double> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final currentColor = isActive
        ? AppColors.primary
        : colors.onSurface.withAlpha(40);
    final step = (max - min) / divisions;

    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          color: currentColor,
        ),

        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: currentColor,
              inactiveTrackColor: colors.onSurface.withAlpha(30),
              trackHeight: 4,
              thumbColor: currentColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),

        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
          icon: const Icon(Icons.add_circle_outline, size: 22),
          color: currentColor,
        ),
      ],
    );
  }

  // 🎚️ SLIDER COMPACTE
  Widget _buildSliderRow({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required bool isActive,
    required ValueChanged<double> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final currentColor = isActive
        ? AppColors.primary
        : colors.onSurface.withAlpha(40);
    final step = (max - min) / divisions;

    return Row(
      children: [
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 28),
          color: currentColor,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: currentColor,
              inactiveTrackColor: colors.onSurface.withAlpha(30),
              trackHeight: isActive ? 6 : 4,
              thumbColor: currentColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          color: currentColor,
        ),
      ],
    );
  }
}
