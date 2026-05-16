import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/alarm_progress.dart';
import 'package:senda/notifiers/helpers/alarm_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSettings {
  final bool distanceEnabled;
  final double distanceMeters;

  final bool altitudeEnabled;
  final double altitudeMeters;

  final bool timeEnabled;
  final int timeSeconds;

  const AlarmSettings({
    this.distanceEnabled = false,
    this.distanceMeters = 100.0,
    this.altitudeEnabled = false,
    this.altitudeMeters = 10.0,
    this.timeEnabled = false,
    this.timeSeconds = 60,
  });

  AlarmSettings copyWith({
    bool? distanceEnabled,
    double? distanceMeters,
    bool? altitudeEnabled,
    double? altitudeMeters,
    bool? timeEnabled,
    int? timeSeconds,
  }) {
    return AlarmSettings(
      distanceEnabled: distanceEnabled ?? this.distanceEnabled,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      altitudeEnabled: altitudeEnabled ?? this.altitudeEnabled,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      timeEnabled: timeEnabled ?? this.timeEnabled,
      timeSeconds: timeSeconds ?? this.timeSeconds,
    );
  }
}

// ───────────────────────────────────────────────
// PROVIDER GLOBAL DEL MOTOR D’ALARMES
// ───────────────────────────────────────────────

final alarmEngineProvider = Provider<AlarmEngine>((ref) {
  return AlarmEngine(ref);
});

// ───────────────────────────────────────────────
// NOTIFIER
// ───────────────────────────────────────────────

class AlarmSettingsNotifier extends Notifier<AlarmSettings> {
  late final Future<void> initialized;

  @override
  AlarmSettings build() {
    initialized = _loadFromPrefs();
    return const AlarmSettings();
  }

  // ───────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────

  bool _anyEnabled(AlarmSettings s) {
    return s.distanceEnabled || s.altitudeEnabled || s.timeEnabled;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final distanceEnabled = prefs.getBool('alarm_distance_enabled') ?? false;
    final distanceMeters = prefs.getDouble('alarm_distance_meters') ?? 100.0;

    final altitudeEnabled = prefs.getBool('alarm_altitude_enabled') ?? false;
    final altitudeMeters = prefs.getDouble('alarm_altitude_meters') ?? 10.0;

    final timeEnabled = prefs.getBool('alarm_time_enabled') ?? false;
    final timeSeconds = prefs.getInt('alarm_time_seconds') ?? 60;

    state = AlarmSettings(
      distanceEnabled: distanceEnabled,
      distanceMeters: distanceMeters,
      altitudeEnabled: altitudeEnabled,
      altitudeMeters: altitudeMeters,
      timeEnabled: timeEnabled,
      timeSeconds: timeSeconds,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('alarm_distance_enabled', state.distanceEnabled);
    await prefs.setDouble('alarm_distance_meters', state.distanceMeters);

    await prefs.setBool('alarm_altitude_enabled', state.altitudeEnabled);
    await prefs.setDouble('alarm_altitude_meters', state.altitudeMeters);

    await prefs.setBool('alarm_time_enabled', state.timeEnabled);
    await prefs.setInt('alarm_time_seconds', state.timeSeconds);
  }

  void _handleEngineTransition(bool before, bool after) {
    final engine = ref.read(alarmEngineProvider);

    if (!before && after) {
      // 0 → 1 alarmes actives
      engine.start();
    } else if (before && !after) {
      // 1 → 0 alarmes actives
      engine.stop();
    }
  }

  // ───────────────────────────────────────────────
  // SETTERS AMB START/STOP AUTOMÀTIC
  // ───────────────────────────────────────────────

  void setDistanceAlarm(bool enabled, double meters) {
    final before = _anyEnabled(state);

    state = state.copyWith(distanceEnabled: enabled, distanceMeters: meters);

    _saveToPrefs();

    final after = _anyEnabled(state);
    _handleEngineTransition(before, after);
  }

  void setAltitudeAlarm(bool enabled, double meters) {
    final before = _anyEnabled(state);

    state = state.copyWith(altitudeEnabled: enabled, altitudeMeters: meters);

    _saveToPrefs();

    final after = _anyEnabled(state);
    _handleEngineTransition(before, after);
  }

  void setTimeAlarm(bool enabled, int seconds) {
    final before = _anyEnabled(state);

    state = state.copyWith(timeEnabled: enabled, timeSeconds: seconds);

    _saveToPrefs();

    final after = _anyEnabled(state);
    _handleEngineTransition(before, after);
  }

  void reset() {
    final before = _anyEnabled(state);

    state = const AlarmSettings();
    _saveToPrefs();

    final after = _anyEnabled(state);
    _handleEngineTransition(before, after);
  }
}

// ───────────────────────────────────────────────
// PROVIDER FINAL
// ───────────────────────────────────────────────

final alarmSettingsProvider =
    NotifierProvider<AlarmSettingsNotifier, AlarmSettings>(
      AlarmSettingsNotifier.new,
    );

final alarmProgressProvider = StreamProvider<AlarmProgress>((ref) {
  return ref.read(alarmEngineProvider).progressStream;
});
