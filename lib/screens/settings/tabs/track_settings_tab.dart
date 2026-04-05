import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/legacy.dart';

final trackSettingsProvider =
    StateNotifierProvider<TrackSettingsNotifier, TrackSettings>((ref) {
      return TrackSettingsNotifier();
    });

class TrackSettings {
  final Color color;
  final double width;

  const TrackSettings({this.color = Colors.blue, this.width = 4});

  TrackSettings copyWith({Color? color, double? width}) {
    return TrackSettings(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}

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

  const TrackSettingsTab({super.key, required this.onPending});

  static void apply(WidgetRef ref) {
    ref.read(trackSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(trackSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------
          // COLOR PICKER
          // -------------------------
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
              // Preview del color actual
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: settings.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.onSurface.withOpacity(0.4),
                    width: 1.5,
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
                          ref.read(trackSettingsProvider.notifier).setColor(c);
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

          // -------------------------
          // SLIDER WIDTH
          // -------------------------
          Text(
            "Gruix del track: ${settings.width.toStringAsFixed(1)}",
            style: TextStyle(fontSize: 16, color: colors.onSurface),
          ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.onSurface.withOpacity(0.2),
              thumbColor: colors.primary,
            ),
            child: Slider(
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
          ),
        ],
      ),
    );
  }
}
