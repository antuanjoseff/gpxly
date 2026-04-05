import 'package:flutter_riverpod/legacy.dart';

final gpxSettingsProvider =
    StateNotifierProvider<GpxSettingsNotifier, GpxSettings>((ref) {
      return GpxSettingsNotifier();
    });

class GpxSettings {
  final bool accuracies;
  final bool speeds;
  final bool headings;
  final bool satellites;
  final bool vAccuracies;
  final bool recording;
  final bool paused;
  final bool duration;
  final bool distance;
  final bool ascent;
  final bool descent;
  final bool maxElevation;
  final bool minElevation;

  const GpxSettings({
    this.accuracies = false,
    this.speeds = false,
    this.headings = false,
    this.satellites = false,
    this.vAccuracies = false,
    this.recording = false,
    this.paused = false,
    this.duration = false,
    this.distance = false,
    this.ascent = false,
    this.descent = false,
    this.maxElevation = false,
    this.minElevation = false,
  });

  GpxSettings copyWith({
    bool? accuracies,
    bool? speeds,
    bool? headings,
    bool? satellites,
    bool? vAccuracies,
    bool? recording,
    bool? paused,
    bool? duration,
    bool? distance,
    bool? ascent,
    bool? descent,
    bool? maxElevation,
    bool? minElevation,
  }) {
    return GpxSettings(
      accuracies: accuracies ?? this.accuracies,
      speeds: speeds ?? this.speeds,
      headings: headings ?? this.headings,
      satellites: satellites ?? this.satellites,
      vAccuracies: vAccuracies ?? this.vAccuracies,
      recording: recording ?? this.recording,
      paused: paused ?? this.paused,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      ascent: ascent ?? this.ascent,
      descent: descent ?? this.descent,
      maxElevation: maxElevation ?? this.maxElevation,
      minElevation: minElevation ?? this.minElevation,
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
      case 'recording':
        state = state.copyWith(recording: value);
        break;
      case 'paused':
        state = state.copyWith(paused: value);
        break;
      case 'duration':
        state = state.copyWith(duration: value);
        break;
      case 'distance':
        state = state.copyWith(distance: value);
        break;
      case 'ascent':
        state = state.copyWith(ascent: value);
        break;
      case 'descent':
        state = state.copyWith(descent: value);
        break;
      case 'maxElevation':
        state = state.copyWith(maxElevation: value);
        break;
      case 'minElevation':
        state = state.copyWith(minElevation: value);
        break;
    }
  }

  void apply() {
    // Aquí pots guardar-ho a SharedPreferences o on vulguis
  }
}
