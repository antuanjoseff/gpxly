import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // DISTÀNCIA
          _buildCompactAlarmCard(
            isActive: settings.distanceEnabled,
            icon: Icons.route,
            title: t.alarmsDistanceTitle,
            valueText: _formatDistance(settings.distanceMeters),
            value: settings.distanceMeters,
            min: 100,
            max: 10000,
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

          // ALTITUD INTEGRADA (Adaptada al teu Notifier actual)
          _buildAltitudeIntegratedCard(settings, t),

          const SizedBox(height: 16),

          // TEMPS
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

  Widget _buildAltitudeIntegratedCard(settings, t) {
    final isAccMode = settings.currentViewMode == AltitudeViewMode.accumulated;

    // Ara mirem els booleans individuals que hem creat al model
    final isCurrentModeActive = isAccMode
        ? settings.accEnabled
        : settings.cotaEnabled;

    final valueText = isAccMode
        ? "+ ${settings.accMeters.toInt()} m"
        : "Cota ${settings.cotaMeters.toInt()} m";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (settings.accEnabled || settings.cotaEnabled)
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
              // Dins del Row de _buildAltitudeIntegratedCard:
              Consumer(
                builder: (context, ref, child) {
                  // Escoltem el progrés només aquí dins per no molestar la resta
                  final progress = ref.watch(alarmProgressProvider).value;

                  // Triem el valor segons si estem en mode Desnivell o Cotes
                  final progressValue = isAccMode
                      ? (progress?.accProgress ?? 0.0)
                      : (progress?.cotaProgress ?? 0.0);

                  return _buildProgressIcon(
                    isCurrentModeActive,
                    progressValue,
                    isAccMode ? Icons.trending_up : Icons.layers,
                    () {
                      ref.read(alarmEngineProvider).sounds.playAltitudeAlarm();
                    },
                  );
                },
              ),

              const SizedBox(width: 12),
              const Text(
                "Altitud",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: isCurrentModeActive,
                onChanged: (_) => _handleToggle(() {
                  // CRIDA ALS MÈTODES REALS DEL NOTIFIER
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
                activeTrackColor: AppColors.primary.withAlpha(
                  150,
                ), // Color del fons
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected))
                    return AppColors.primary; // Botó blau fort
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
                label: const Text("Desnivell"),
                icon: settings.accEnabled
                    ? const Icon(Icons.check_circle, size: 14)
                    : const Icon(Icons.show_chart, size: 16),
              ),
              ButtonSegment(
                value: AltitudeViewMode.absolute,
                label: const Text("Cotes"),
                icon: settings.cotaEnabled
                    ? const Icon(Icons.check_circle, size: 14)
                    : const Icon(Icons.straighten, size: 16),
              ),
            ],
            // LLEGIM DEL NOTIFIER
            selected: {settings.currentViewMode},
            // ESCRIVIM AL NOTIFIER
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

            // 🏔️ DESNIVELL: Min 50, Max 1000 | 📍 COTA: Min 10, Max 5000
            min: isAccMode ? 10.0 : 50.0,
            max: isAccMode ? 1000.0 : 5000.0,

            // 🏔️ DESNIVELL: Steps de 50 | 📍 COTA: Steps de 10
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
    // Definim el color dels botons segons si l'alarma està activa
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
              color: buttonColor, // Color dinàmic
              onPressed: isActive && value > min
                  ? () {
                      HapticFeedback.lightImpact();
                      // Calculem el nou valor sense baixar del mínim
                      final newVal = (value - 10).clamp(min, max);
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
              color: buttonColor, // Color dinàmic
              onPressed: isActive && value < max
                  ? () {
                      HapticFeedback.lightImpact();
                      // Calculem el nou valor sense passar del màxim
                      final newVal = (value + 10).clamp(min, max);
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
              // Dins del Row de _buildCompactAlarmCard:
              Consumer(
                builder: (context, ref, child) {
                  // Escoltem el progrés aquí dins
                  final progress = ref.watch(alarmProgressProvider).value;

                  // Decidim quin valor mostrar segons la icona de la targeta
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
                activeTrackColor: AppColors.primary.withAlpha(
                  150,
                ), // Color del fons
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected))
                    return AppColors.primary; // Botó blau fort
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
