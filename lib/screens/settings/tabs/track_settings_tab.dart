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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Color del track", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Selecciona color"),
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

          const SizedBox(height: 32),

          Text("Gruix: ${settings.width.toStringAsFixed(1)}"),
          Slider(
            value: settings.width,
            min: 1,
            max: 10,
            onChanged: (v) {
              ref.read(trackSettingsProvider.notifier).setWidth(v);
              onPending();
            },
          ),
        ],
      ),
    );
  }
}
