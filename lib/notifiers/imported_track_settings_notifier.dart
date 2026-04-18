import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track_settings.dart';

class ImportedTrackSettingsNotifier extends Notifier<TrackSettings> {
  @override
  TrackSettings build() {
    final initial = const TrackSettings();

    _loadFromPrefs();
    return initial;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedColor = prefs.getInt('imported_track_color');
    final savedWidth = prefs.getDouble('imported_track_width');

    state = TrackSettings(
      color: savedColor != null ? Color(savedColor) : state.color,
      width: savedWidth ?? state.width,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('imported_track_color', state.color.value);
    await prefs.setDouble('imported_track_width', state.width);
  }

  void setColor(Color c) {
    state = state.copyWith(color: c);
    _saveToPrefs();
  }

  void setWidth(double w) {
    state = state.copyWith(width: w);
    _saveToPrefs();
  }

  void apply() {
    _saveToPrefs();
  }
}

final importedTrackSettingsProvider =
    NotifierProvider<ImportedTrackSettingsNotifier, TrackSettings>(
      ImportedTrackSettingsNotifier.new,
    );
