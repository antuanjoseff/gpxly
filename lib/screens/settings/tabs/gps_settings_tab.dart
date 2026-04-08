import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class GpsSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const GpsSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

  static void apply(WidgetRef ref) {
    ref.read(gpsSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gps = ref.watch(gpsSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- BLOC TEMPS ---
            _buildSettingsCard(
              isActive: gps.useTime,
              title: "Gravació per temps",
              valueText: "${gps.seconds} s", // Text simplificat
              sliderRow: _buildSliderRow(
                context: context,
                value: gps.seconds.toDouble(),
                min: 2,
                max: 60,
                divisions: 58,
                isActive: gps.useTime,
                onChanged: (val) {
                  ref
                      .read(gpsSettingsProvider.notifier)
                      .setSeconds(val.round());
                  ref.read(gpsSettingsProvider.notifier).setUseTime(true);
                  onPending();
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- BLOC METRES ---
            _buildSettingsCard(
              isActive: !gps.useTime,
              title: "Gravació per distància",
              valueText: "${gps.meters.toInt()} m", // Text simplificat
              sliderRow: _buildSliderRow(
                context: context,
                value: gps.meters,
                min: 1,
                max: 100,
                divisions: 99,
                isActive: !gps.useTime,
                onChanged: (val) {
                  ref.read(gpsSettingsProvider.notifier).setMeters(val);
                  ref.read(gpsSettingsProvider.notifier).setUseTime(false);
                  onPending();
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- BLOC ACCURACY ---
            _buildSettingsCard(
              isActive: true,
              title: "Accuracy màxima",
              valueText: "${gps.accuracy.toInt()} m", // Text simplificat
              sliderRow: _buildSliderRow(
                context: context,
                value: gps.accuracy,
                min: 5,
                max: 100,
                divisions: 19,
                isActive: true,
                onChanged: (val) {
                  ref.read(gpsSettingsProvider.notifier).setAccuracy(val);
                  onPending();
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isActive,
    required String title,
    required String valueText,
    required Widget sliderRow,
  }) {
    return Container(
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
                  // Gris més clar per al títol inactiu
                  color: isActive ? AppColors.primary : Colors.grey[400],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // Gris gairebé blanc per al fons de la càpsula inactiva
                  color: isActive ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    // Gris suau per al text de la càpsula inactiva
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
