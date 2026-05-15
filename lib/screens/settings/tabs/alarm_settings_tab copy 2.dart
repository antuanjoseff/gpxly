import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _tick = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _engine = AlarmEngine(ref);

    _tick.setVolume(0.4);
  }

  @override
  void dispose() {
    _engine.stop();
    _tick.dispose();
    super.dispose();
  }

  Future<void> _playTick() async {
    await _tick.play(AssetSource("sounds/tick.mp3"));
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
  // UNITATS INTEL·LIGENTS
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
          // ───────────────────────────────────────────────
          // DISTÀNCIA
          // ───────────────────────────────────────────────
          _buildAlarmSwitch(
            context: context,
            value: settings.distanceEnabled,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setDistanceAlarm(
                    !settings.distanceEnabled,
                    settings.distanceMeters,
                  );
              _handleAlarmToggle();
            },
          ),
          const SizedBox(height: 12),

          if (settings.distanceEnabled)
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 200),
              child: _buildSettingsCard(
                isActive: true,
                title: t.alarmsDistanceTitle,
                valueText: _formatDistance(settings.distanceMeters),
                sliderRow: _buildSliderRow(
                  context: context,
                  value: settings.distanceMeters,
                  min: 100,
                  max: 10000,
                  divisions: 99,
                  isActive: true,
                  onChanged: (val) {
                    ref
                        .read(alarmSettingsProvider.notifier)
                        .setDistanceAlarm(true, val);
                    _playTick();
                  },
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ───────────────────────────────────────────────
          // ALTITUD
          // ───────────────────────────────────────────────
          _buildAlarmSwitch(
            context: context,
            value: settings.altitudeEnabled,
            icon: Icons.height,
            title: t.alarmsAltitudeTitle,
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setAltitudeAlarm(
                    !settings.altitudeEnabled,
                    settings.altitudeMeters,
                  );
              _handleAlarmToggle();
            },
          ),
          const SizedBox(height: 12),

          if (settings.altitudeEnabled)
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 200),
              child: _buildSettingsCard(
                isActive: true,
                title: t.alarmsAltitudeTitle,
                valueText: "${settings.altitudeMeters.toInt()} m",
                sliderRow: _buildSliderRow(
                  context: context,
                  value: settings.altitudeMeters,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  isActive: true,
                  onChanged: (val) {
                    ref
                        .read(alarmSettingsProvider.notifier)
                        .setAltitudeAlarm(true, val);
                    _playTick();
                  },
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ───────────────────────────────────────────────
          // TEMPS
          // ───────────────────────────────────────────────
          _buildAlarmSwitch(
            context: context,
            value: settings.timeEnabled,
            icon: Icons.timer,
            title: t.alarmsTimeTitle,
            onToggle: () {
              ref
                  .read(alarmSettingsProvider.notifier)
                  .setTimeAlarm(!settings.timeEnabled, settings.timeSeconds);
              _handleAlarmToggle();
            },
          ),
          const SizedBox(height: 12),

          if (settings.timeEnabled)
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 200),
              child: _buildSettingsCard(
                isActive: true,
                title: t.alarmsTimeTitle,
                valueText: _formatTime(settings.timeSeconds),
                sliderRow: _buildSliderRow(
                  context: context,
                  value: settings.timeSeconds.toDouble(),
                  min: 60,
                  max: 3600,
                  divisions: 59,
                  isActive: true,
                  onChanged: (val) {
                    ref
                        .read(alarmSettingsProvider.notifier)
                        .setTimeAlarm(true, val.round());
                    _playTick();
                  },
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // SWITCH PERSONALITZAT
  // ───────────────────────────────────────────────

  Widget _buildAlarmSwitch({
    required BuildContext context,
    required bool value,
    required IconData icon,
    required String title,
    required VoidCallback onToggle,
  }) {
    final t = AppLocalizations.of(context)!;

    return Container(
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
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(
                icon,
                color: value ? AppColors.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: value ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value ? t.switchOn : t.switchOff,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // SETTINGS CARD
  // ───────────────────────────────────────────────

  Widget _buildSettingsCard({
    required bool isActive,
    required String title,
    required String valueText,
    required Widget sliderRow,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : Colors.grey[400],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          sliderRow,
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
