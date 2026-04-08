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
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // SLIDER TEMPS
            // -------------------------
            Text(
              "Gravació per temps",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada ${gps.seconds} segons",
              style: TextStyle(
                fontSize: 16,
                color: gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
                inactiveTrackColor: colors.onSurface.withAlpha(40),
                trackHeight: gps.useTime ? 6 : 3,
                thumbColor: gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
              child: Slider(
                value: gps.seconds.toDouble(),
                min: 2,
                max: 60,
                divisions: 59,
                label: gps.seconds.toString(),
                onChanged: (val) {
                  ref
                      .read(gpsSettingsProvider.notifier)
                      .setSeconds(val.round());
                  ref.read(gpsSettingsProvider.notifier).setUseTime(true);
                  onPending();
                },
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------
            // SLIDER METRES
            // -------------------------
            Text(
              "Gravació per distància",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: !gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada ${gps.meters.toInt()} metres",
              style: TextStyle(
                fontSize: 16,
                color: !gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: !gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
                inactiveTrackColor: colors.onSurface.withAlpha(40),
                trackHeight: !gps.useTime ? 6 : 3,
                thumbColor: !gps.useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
              child: Slider(
                value: gps.meters,
                min: 1,
                max: 100,
                divisions: 99,
                label: gps.meters.toInt().toString(),
                onChanged: (val) {
                  ref.read(gpsSettingsProvider.notifier).setMeters(val);
                  ref.read(gpsSettingsProvider.notifier).setUseTime(false);
                  onPending();
                },
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------
            // SLIDER ACCURACY
            // -------------------------
            Text(
              "Accuracy màxima",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "${gps.accuracy.toInt()} metres",
              style: TextStyle(fontSize: 16, color: colors.onSurface),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: colors.onSurface.withAlpha(51),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: gps.accuracy,
                min: 5,
                max: 100,
                divisions: 19,
                label: gps.accuracy.toInt().toString(),
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
}
