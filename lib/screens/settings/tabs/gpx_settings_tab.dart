import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gpx_settings_provider.dart';

class GpxSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;

  const GpxSettingsTab({super.key, required this.onPending});

  static void apply(WidgetRef ref) {
    ref.read(gpxSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _switch(ref, settings.accuracies, "accuracies", "Accuracy per punt"),
        _switch(ref, settings.speeds, "speeds", "Velocitat"),
        _switch(ref, settings.headings, "headings", "Heading"),
        _switch(ref, settings.satellites, "satellites", "Satèl·lits"),
        _switch(ref, settings.vAccuracies, "vAccuracies", "Vertical accuracy"),
      ],
    );
  }

  Widget _switch(WidgetRef ref, bool value, String field, String title) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) {
        ref.read(gpxSettingsProvider.notifier).toggle(field, v);
        onPending();
      },
    );
  }
}
