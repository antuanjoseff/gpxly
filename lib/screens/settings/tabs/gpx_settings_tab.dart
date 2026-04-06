import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gpx_settings_provider.dart';
import 'package:gpxly/theme/app_colors.dart';

class GpxSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const GpxSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

  static void apply(WidgetRef ref) {
    ref.read(gpxSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // -------------------------
        // CONTINGUT DELS SWITCHES
        // -------------------------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _switch(
                context,
                ref,
                settings.accuracies,
                "accuracies",
                "Accuracy per punt",
                colors,
              ),
              _switch(
                context,
                ref,
                settings.speeds,
                "speeds",
                "Velocitat",
                colors,
              ),
              _switch(
                context,
                ref,
                settings.headings,
                "headings",
                "Heading",
                colors,
              ),
              _switch(
                context,
                ref,
                settings.satellites,
                "satellites",
                "Satèl·lits",
                colors,
              ),
              _switch(
                context,
                ref,
                settings.vAccuracies,
                "vAccuracies",
                "Vertical accuracy",
                colors,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switch(
    BuildContext context,
    WidgetRef ref,
    bool value,
    String field,
    String title,
    ColorScheme colors,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.secondary,
        inactiveThumbColor: AppColors.white,
        inactiveTrackColor: AppColors.tertiary.withAlpha(120),
        onChanged: (v) {
          ref.read(gpxSettingsProvider.notifier).toggle(field, v);
          onPending();
        },
      ),
    );
  }
}
