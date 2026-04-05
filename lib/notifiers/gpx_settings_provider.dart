import 'package:flutter_riverpod/legacy.dart';

final gpxSettingsProvider =
    StateNotifierProvider<GpxSettingsNotifier, GpxSettings>((ref) {
      return GpxSettingsNotifier();
    });

class GpxSettings {
  final bool accuracies; // Horizontal accuracy
  final bool speeds; // Speed
  final bool headings; // Heading / bearing
  final bool satellites; // Satellite count
  final bool vAccuracies; // Vertical accuracy

  const GpxSettings({
    this.accuracies = false,
    this.speeds = false,
    this.headings = false,
    this.satellites = false,
    this.vAccuracies = false,
  });

  GpxSettings copyWith({
    bool? accuracies,
    bool? speeds,
    bool? headings,
    bool? satellites,
    bool? vAccuracies,
  }) {
    return GpxSettings(
      accuracies: accuracies ?? this.accuracies,
      speeds: speeds ?? this.speeds,
      headings: headings ?? this.headings,
      satellites: satellites ?? this.satellites,
      vAccuracies: vAccuracies ?? this.vAccuracies,
    );
  }
}

class GpxSettingsNotifier extends StateNotifier<GpxSettings> {
  GpxSettingsNotifier() : super(const GpxSettings());

  void toggle(String field, bool value) {
    switch (field) {
      case 'accuracies':
        state = state.copyWith(accuracies: value);
        break;
      case 'speeds':
        state = state.copyWith(speeds: value);
        break;
      case 'headings':
        state = state.copyWith(headings: value);
        break;
      case 'satellites':
        state = state.copyWith(satellites: value);
        break;
      case 'vAccuracies':
        state = state.copyWith(vAccuracies: value);
        break;
    }
  }

  void apply() {
    // Aquí pots guardar-ho a SharedPreferences si vols
  }
}
