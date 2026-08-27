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
    final progress = ref.watch(alarmProgressProvider).value;

    return Scaffold(
      backgroundColor: Colors.white, // Fons blanc net professional
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.alarms,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Força a ocupar el mínim espai
            children: [
              _buildVolumeControl(context, ref, t, settings.volume),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),

              // 📊 1. FILA DE DISTÀNCIA
              _buildRowAlarm(
                isActive: settings.distanceEnabled,
                icon: Icons.route,
                title: t.alarmsDistanceTitle,
                valueText: _formatDistance(settings.distanceMeters),
                value: settings.distanceMeters,
                min: 100,
                max: 5000,
                step: 100,
                progressValue: settings.distanceEnabled
                    ? (progress?.distance ?? 0.0)
                    : 0.0,
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
              const Divider(height: 1, color: Color(0xFFE5E5EA)),

              // 📊 2. FILA DE COTA (ALTITUD ABSOLUTA)
              _buildRowAlarm(
                isActive: settings.cotaEnabled,
                icon: Icons.layers,
                title: t.alarmsCotaSegmentLabel, // O el text l10n propi de Cota
                valueText: t.alarmsCotaValue(settings.cotaMeters.toInt()),
                value: settings.cotaMeters,
                min: 50.0,
                max: 1000.0,
                step: 50.0,
                progressValue: settings.cotaEnabled
                    ? (progress?.cotaProgress ?? 0.0)
                    : 0.0,
                onChanged: (val) => ref
                    .read(alarmSettingsProvider.notifier)
                    .setCotaAlarm(settings.cotaEnabled, val),
                onToggle: () => _handleToggle(
                  () => ref
                      .read(alarmSettingsProvider.notifier)
                      .setCotaAlarm(!settings.cotaEnabled, settings.cotaMeters),
                ),
                onPlaySound: () =>
                    ref.read(alarmEngineProvider).sounds.playCotaAlarm(),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),

              // 📊 3. FILA DE DESNIVELL ACUMULAT
              _buildRowAlarm(
                isActive: settings.accEnabled,
                icon: Icons.trending_up,
                title: t
                    .alarmsAccSegmentLabel, // O el text l10n propi de Desnivell
                valueText: "+ ${settings.accMeters.toInt()} m",
                value: settings.accMeters,
                min: 10.0,
                max: 1000.0,
                step: 10.0,
                progressValue: settings.accEnabled
                    ? (progress?.accProgress ?? 0.0)
                    : 0.0,
                onChanged: (val) => ref
                    .read(alarmSettingsProvider.notifier)
                    .setAccAlarm(settings.accEnabled, val),
                onToggle: () => _handleToggle(
                  () => ref
                      .read(alarmSettingsProvider.notifier)
                      .setAccAlarm(!settings.accEnabled, settings.accMeters),
                ),
                onPlaySound: () =>
                    ref.read(alarmEngineProvider).sounds.playAccumulatedAlarm(),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),

              // 📊 4. FILA DE TEMPS
              _buildRowAlarm(
                isActive: settings.timeEnabled,
                icon: Icons.timer,
                title: t.alarmsTimeTitle,
                valueText: _formatTime(settings.timeSeconds),
                value: settings.timeSeconds.toDouble(),
                min: 60,
                max: 3600,
                step: 60,
                progressValue: settings.timeEnabled
                    ? (progress?.time ?? 0.0)
                    : 0.0,
                onChanged: (val) => ref
                    .read(alarmSettingsProvider.notifier)
                    .setTimeAlarm(settings.timeEnabled, val.round()),
                onToggle: () => _handleToggle(
                  () => ref
                      .read(alarmSettingsProvider.notifier)
                      .setTimeAlarm(
                        !settings.timeEnabled,
                        settings.timeSeconds,
                      ),
                ),
                onPlaySound: () =>
                    ref.read(alarmEngineProvider).sounds.playTimeAlarm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
    double volume,
  ) {
    final percentage = (volume * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.alarmsVolume,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withAlpha(30),
              onChanged: (value) =>
                  ref.read(alarmSettingsProvider.notifier).setVolume(value),
            ),
          ),
        ],
      ),
    );
  }

  // Component amb Switch personalitzat que conté els textos ON/OFF a dins
  Widget _buildRowAlarm({
    required bool isActive,
    required IconData icon,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required double step,
    required double progressValue,
    required ValueChanged<double> onChanged,
    required VoidCallback onToggle,
    required VoidCallback onPlaySound,
  }) {
    final color = isActive ? AppColors.primary : Colors.grey.shade400;

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── LÍNIA 1: ICONA, TÍTOL, METRICA I TEXT-SWITCHER ───
            Row(
              children: [
                // Icona de progrés + Play MP3
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        strokeWidth: 2.5,
                        backgroundColor: Colors.grey.withAlpha(30),
                        color: color,
                      ),
                    ),
                    IconButton(
                      icon: Icon(icon, size: 18),
                      color: color,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onPlaySound,
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Títol de l'alarma (Flexible)
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

                // Mètrica / Valor actual
                Text(
                  valueText,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),

                // 🎛️ Switcher personalitzat amb text animat a dins
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggle();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58, // Amplada fixa per encabir el mecanisme i text
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
                        // Textos de fons que queden al descobert
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
                        // La "boleta" o píndola lliscant que tapa el text inactiu
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
            ),

            const SizedBox(height: 8), // Separació entre línies
            // ─── LÍNIA 2: BOTONS DE CONTROL I SLIDER ───
            Row(
              children: [
                // 1.- Botó Menys
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
                          onChanged((value - step).clamp(min, max));
                        }
                      : null,
                ),

                // 2.- Slider
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
                      divisions: ((max - min) / step).round(),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withAlpha(30),
                      onChanged: isActive ? onChanged : null,
                    ),
                  ),
                ),

                // 3.- Botó Més
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
                          onChanged((value + step).clamp(min, max));
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

  Future<void> _handleToggle(VoidCallback action) async {
    if (await PermissionsService.ensurePermissions(context)) {
      HapticFeedback.mediumImpact();
      action();
    }
  }
}
