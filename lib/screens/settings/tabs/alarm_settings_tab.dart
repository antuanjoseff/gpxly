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
      backgroundColor: Colors.white,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔊 CONTROL DE VOLUMEN (Cápsula independiente y fija superior)
              _buildVolumeControl(context, ref, t, settings.volume),

              const SizedBox(height: 14),

              Text(
                t.alarms.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              // 📦 CONTENEDOR PRINCIPAL DE ALARMAS (Flexible sin provocar scroll)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 📊 1. DISTANCIA
                      Expanded(
                        child: _buildRowAlarm(
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
                          onPlaySound: () => ref
                              .read(alarmEngineProvider)
                              .sounds
                              .playDistanceAlarm(),
                        ),
                      ),

                      // 📊 2. COTA (ALTITUD ABSOLUTA)
                      Expanded(
                        child: _buildRowAlarm(
                          isActive: settings.cotaEnabled,
                          icon: Icons.height_outlined,
                          title: t.alarmsCotaSegmentLabel,
                          valueText: t.alarmsCotaValue(
                            settings.cotaMeters.toInt(),
                          ),
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
                                .setCotaAlarm(
                                  !settings.cotaEnabled,
                                  settings.cotaMeters,
                                ),
                          ),
                          onPlaySound: () => ref
                              .read(alarmEngineProvider)
                              .sounds
                              .playCotaAlarm(),
                        ),
                      ),

                      // 📊 3. DESNIVEL ACUMULADO
                      Expanded(
                        child: _buildRowAlarm(
                          isActive: settings.accEnabled,
                          icon: Icons.trending_up,
                          title: t.alarmsAccSegmentLabel,
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
                                .setAccAlarm(
                                  !settings.accEnabled,
                                  settings.accMeters,
                                ),
                          ),
                          onPlaySound: () => ref
                              .read(alarmEngineProvider)
                              .sounds
                              .playAccumulatedAlarm(),
                        ),
                      ),

                      // 📊 4. TIEMPO
                      Expanded(
                        child: _buildRowAlarm(
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
                          onPlaySound: () => ref
                              .read(alarmEngineProvider)
                              .sounds
                              .playTimeAlarm(),
                        ),
                      ),
                    ],
                  ),
                ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.alarmsVolume,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withAlpha(30),
              thumbColor: AppColors.primary,
            ),
            child: SizedBox(
              height: 24,
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) =>
                    ref.read(alarmSettingsProvider.notifier).setVolume(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    final color = isActive ? AppColors.primary : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── LÍNEA 1: ICONO, TÍTULO, MÉTRICA Y SWITCH ANIMADO ───
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: progressValue.clamp(0.0, 1.0),
                      strokeWidth: 2.0,
                      backgroundColor: Colors.grey.withAlpha(20),
                      color: color,
                    ),
                  ),
                  IconButton(
                    icon: Icon(icon, size: 16),
                    color: color,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onPlaySound,
                  ),
                ],
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Text(
                isActive ? valueText : "--",
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),

              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 26,
                  padding: const EdgeInsets.all(2),
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
                            fontSize: 9,
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
                            fontSize: 9,
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
                          width: 20,
                          height: 20,
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

          // ─── LÍNEA 2: BOTONES DE CONTROL (+ / -) Y SLIDER DE ALTURA FIJA ───
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isActive
                ? Column(
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // 1.- Botón Menos Rápido
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            color: AppColors.primary,
                            disabledColor: Colors.grey.shade300,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: isActive && value > min
                                ? () {
                                    HapticFeedback.lightImpact();
                                    onChanged((value - step).clamp(min, max));
                                  }
                                : null,
                          ),

                          // 2.- Slider Adaptativo
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.grey.shade200,
                                thumbColor: AppColors.primary,
                              ),
                              child: SizedBox(
                                height:
                                    24, // Limita estrictamente el alto para evitar desbordes
                                child: Slider(
                                  value: value.clamp(min, max),
                                  min: min,
                                  max: max,
                                  divisions: ((max - min) / step).round(),
                                  onChanged: onChanged,
                                ),
                              ),
                            ),
                          ),

                          // 3.- Botón Más Rápido
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            color: AppColors.primary,
                            disabledColor: Colors.grey.shade300,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
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
                  )
                : const SizedBox.shrink(),
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
