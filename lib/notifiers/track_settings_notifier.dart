import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track_settings.dart';

class TrackSettingsNotifier extends Notifier<TrackSettings> {
  @override
  TrackSettings build() {
    final initial = TrackSettings(color: AppColors.recordedTrackColor);

    _loadFromPrefs();
    return initial;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedColor = prefs.getInt('track_color');
    final savedWidth = prefs.getDouble('track_width');

    state = state.copyWith(
      color: savedColor != null ? Color(savedColor) : state.color,
      width: savedWidth ?? state.width,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('track_color', state.color.value);
    await prefs.setDouble('track_width', state.width);
  }

  Future<void> setColor(Color c) async {
    state = state.copyWith(color: c);
    await _saveToPrefs();
  }

  Future<void> setWidth(double w) async {
    state = state.copyWith(width: w);
    await _saveToPrefs();
  }
}

final trackSettingsProvider =
    NotifierProvider<TrackSettingsNotifier, TrackSettings>(
      TrackSettingsNotifier.new,
    );
