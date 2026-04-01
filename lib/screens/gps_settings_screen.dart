import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_settings_provider.dart';

class GpsSettingsScreen extends ConsumerWidget {
  const GpsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsSettings = ref.watch(gpsSettingsProvider);
    final notifier = ref.read(gpsSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuració GPS')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Toggle entre temps i distància
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Icon(Icons.timer),
                  selected: gpsSettings.useTime,
                  onSelected: (val) {
                    notifier.setUseTime(true);
                  },
                ),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Icon(Icons.straighten),
                  selected: !gpsSettings.useTime,
                  onSelected: (val) {
                    notifier.setUseTime(false);
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Slider segons
            if (gpsSettings.useTime)
              Column(
                children: [
                  Slider(
                    value: gpsSettings.seconds.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: gpsSettings.seconds.toString(),
                    onChanged: (val) {
                      notifier.state = gpsSettings.copyWith(
                        seconds: val.toInt(),
                      );
                    },
                  ),
                  const Icon(Icons.timer),
                ],
              ),

            // Slider metres
            if (!gpsSettings.useTime)
              Column(
                children: [
                  Slider(
                    value: gpsSettings.meters.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 95,
                    label: gpsSettings.meters.toString(),
                    onChanged: (val) {
                      notifier.state = gpsSettings.copyWith(
                        meters: val.toInt(),
                      );
                    },
                  ),
                  const Icon(Icons.straighten),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
