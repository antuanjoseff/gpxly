import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/helpers/alarm_engine.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/theme/app_colors.dart';

class AlarmSettingsTab extends ConsumerStatefulWidget {
  const AlarmSettingsTab({super.key});

  @override
  ConsumerState<AlarmSettingsTab> createState() => _AlarmSettingsTabState();
}

class _AlarmSettingsTabState extends ConsumerState<AlarmSettingsTab> {
  late final AlarmEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = AlarmEngine(ref);
  }

  @override
  void dispose() {
    _engine.stop();
    super.dispose();
  }

  Future<void> _handleAlarmToggle() async {
    final settings = ref.read(alarmSettingsProvider);

    final anyEnabled =
        settings.distanceEnabled ||
        settings.altitudeEnabled ||
        settings.timeEnabled;

    if (anyEnabled) {
      final ok = await PermissionsService.ensureGpsReady(context);
      if (!ok) return;

      await ref.read(trackProvider.notifier).ensureGpsStarted();
      await _engine.start();
    } else {
      _engine.stop();
      ref.read(trackProvider.notifier).stopGpsIfNotNeeded();
    }
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(backgroundColor: AppColors.primary, title: Text(t.alarms)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // DISTÀNCIA
          _buildAlarmCard(
            context: context,
            isActive: settings.distanceEnabled,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            valueText: _formatDistance(settings.distanceMeters),
            sliderRow: _buildSliderRow(
              context: context,
              value: settings.distanceMeters,
              min: 100,
              max: 10000,
              divisions: 99,
              isActive: settings.distanceEnabled,
              onChanged: (val) {
                ref
                    .read(alarmSettingsProvider.notifier)
                    .setDistanceAlarm(true, val);
              },
            ),
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setDistanceAlarm(
                    !settings.distanceEnabled,
                    settings.distanceMeters,
                  );
              _handleAlarmToggle();
            },
            onPlaySound: () => _engine.sounds.playDistanceAlarm(),
          ),

          const SizedBox(height: 24),

          // ALTITUD
          _buildAlarmCard(
            context: context,
            isActive: settings.altitudeEnabled,
            icon: Icons.height,
            title: t.alarmsAltitudeTitle,
            valueText: "${settings.altitudeMeters.toInt()} m",
            sliderRow: _buildSliderRow(
              context: context,
              value: settings.altitudeMeters,
              min: 0,
              max: 500,
              divisions: 50,
              isActive: settings.altitudeEnabled,
              onChanged: (val) {
                ref
                    .read(alarmSettingsProvider.notifier)
                    .setAltitudeAlarm(true, val);
              },
            ),
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeAlarm(
                    !settings.altitudeEnabled,
                    settings.altitudeMeters,
                  );
              _handleAlarmToggle();
            },
            onPlaySound: () => _engine.sounds.playAltitudeAlarm(),
          ),

          const SizedBox(height: 24),

          // TEMPS
          _buildAlarmCard(
            context: context,
            isActive: settings.timeEnabled,
            icon: Icons.timer,
            title: t.alarmsTimeTitle,
            valueText: _formatTime(settings.timeSeconds),
            sliderRow: _buildSliderRow(
              context: context,
              value: settings.timeSeconds.toDouble(),
              min: 60,
              max: 3600,
              divisions: 59,
              isActive: settings.timeEnabled,
              onChanged: (val) {
                ref
                    .read(alarmSettingsProvider.notifier)
                    .setTimeAlarm(true, val.round());
              },
            ),
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setTimeAlarm(!settings.timeEnabled, settings.timeSeconds);
              _handleAlarmToggle();
            },
            onPlaySound: () => _engine.sounds.playTimeAlarm(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // CARD COMPACTAT (switch + valor + slider)
  // ───────────────────────────────────────────────

  Widget _buildAlarmCard({
    required BuildContext context,
    required bool isActive,
    required IconData icon,
    required String title,
    required String valueText,
    required Widget sliderRow,
    required VoidCallback onToggle,
    required VoidCallback onPlaySound,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
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
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppColors.primary : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ],
              ),

              Switch(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),

          // VALUE + SOUND
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isActive
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    color: AppColors.primary,
                    onPressed: onPlaySound,
                  ),
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          // SLIDER
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isActive
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: sliderRow,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // SLIDER
  // ───────────────────────────────────────────────

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
