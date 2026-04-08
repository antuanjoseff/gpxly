import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gpx_settings.dart';

class GpxSettingsNotifier extends Notifier<GpxSettings> {
  @override
  GpxSettings build() {
    final initial = const GpxSettings();
    _loadFromPrefs();
    return initial;
  }

  // -----------------------------
  // LOAD
  // -----------------------------
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    state = state.copyWith(
      accuracies: prefs.getBool('gpx_accuracies') ?? state.accuracies,
      speeds: prefs.getBool('gpx_speeds') ?? state.speeds,
      headings: prefs.getBool('gpx_headings') ?? state.headings,
      satellites: prefs.getBool('gpx_satellites') ?? state.satellites,
      vAccuracies: prefs.getBool('gpx_vAccuracies') ?? state.vAccuracies,
    );
  }

  // -----------------------------
  // SAVE
  // -----------------------------
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('gpx_accuracies', state.accuracies);
    await prefs.setBool('gpx_speeds', state.speeds);
    await prefs.setBool('gpx_headings', state.headings);
    await prefs.setBool('gpx_satellites', state.satellites);
    await prefs.setBool('gpx_vAccuracies', state.vAccuracies);
  }

  // -----------------------------
  // UPDATE
  // -----------------------------
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

    _saveToPrefs();
  }

  void apply() {
    _saveToPrefs();
  }
}

final gpxSettingsProvider = NotifierProvider<GpxSettingsNotifier, GpxSettings>(
  GpxSettingsNotifier.new,
);
