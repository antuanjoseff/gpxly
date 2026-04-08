import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gpxly/models/track_settings.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';

class TrackSettingsNotifier extends StateNotifier<TrackSettings> {
  TrackSettingsNotifier() : super(const TrackSettings());

  void setColor(Color c) => state = state.copyWith(color: c);
  void setWidth(double w) => state = state.copyWith(width: w);

  void apply() {
    // guardar preferències
  }
}

class TrackSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const TrackSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

  static void apply(WidgetRef ref) {
    ref.read(trackSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(trackSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Color del track",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(
                        width: 80,
                        height: settings.width,
                        decoration: BoxDecoration(
                          color: settings.color,
                          borderRadius: BorderRadius.circular(
                            settings.width / 2,
                          ),
                          border: Border.all(
                            color: colors.onSurface.withAlpha(100),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: colors.surface,
                            title: Text(
                              "Selecciona color",
                              style: TextStyle(color: colors.onSurface),
                            ),
                            content: BlockPicker(
                              pickerColor: settings.color,
                              onColorChanged: (c) {
                                ref
                                    .read(trackSettingsProvider.notifier)
                                    .setColor(c);
                                onPending();
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text("Canvia color"),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  "Gruix del track: ${settings.width.toStringAsFixed(1)}",
                  style: TextStyle(fontSize: 16, color: colors.onSurface),
                ),

                Slider(
                  value: settings.width,
                  min: 1,
                  max: 10,
                  divisions: 18,
                  label: settings.width.toStringAsFixed(1),
                  onChanged: (v) {
                    ref.read(trackSettingsProvider.notifier).setWidth(v);
                    onPending();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
