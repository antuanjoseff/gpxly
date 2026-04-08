import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track_settings.dart';

class TrackSettingsNotifier extends Notifier<TrackSettings> {
  @override
  TrackSettings build() {
    // Estat inicial per defecte
    final initial = const TrackSettings();

    // Carregar preferències guardades
    _loadFromPrefs();

    return initial;
  }

  // -----------------------------
  // LOAD
  // -----------------------------
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedColor = prefs.getInt('track_color');
    final savedWidth = prefs.getDouble('track_width');

    // IMPORTANT: build() ja ha retornat un estat inicial,
    // així que aquí fem un update() del state.
    state = TrackSettings(
      color: savedColor != null ? Color(savedColor) : state.color,
      width: savedWidth ?? state.width,
    );
  }

  // -----------------------------
  // SAVE
  // -----------------------------
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('track_color', state.color.value);
    await prefs.setDouble('track_width', state.width);
  }

  // -----------------------------
  // UPDATE METHODS
  // -----------------------------
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

final trackSettingsProvider =
    NotifierProvider<TrackSettingsNotifier, TrackSettings>(
      TrackSettingsNotifier.new,
    );
