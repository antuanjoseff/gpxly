import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/alarm_progress.dart';
import 'package:strack_rec/notifiers/helpers/alarm_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Primer definim l'enum fora de la classe (o importa'l si ja el tens en un fitxer de models)
enum AltitudeViewMode { accumulated, absolute }

class AlarmSettings {
  final bool distanceEnabled;
  final double distanceMeters;

  // Altitud Desnivel (Acumulado)
  final bool accEnabled;
  final double accMeters;

  // Altitud Cotes (Absoluto)
  final bool cotaEnabled;
  final double cotaMeters;

  final bool timeEnabled;
  final int timeSeconds;

  final AltitudeViewMode currentViewMode;

  const AlarmSettings({
    this.distanceEnabled = false,
    this.distanceMeters = 100.0,
    this.accEnabled = false,
    this.accMeters = 100.0,
    this.cotaEnabled = false,
    this.cotaMeters = 500.0,
    this.timeEnabled = false,
    this.timeSeconds = 60,
    // Per defecte obrim desnivell
    this.currentViewMode = AltitudeViewMode.accumulated,
  });

  AlarmSettings copyWith({
    bool? distanceEnabled,
    double? distanceMeters,
    bool? accEnabled,
    double? accMeters,
    bool? cotaEnabled,
    double? cotaMeters,
    bool? timeEnabled,
    int? timeSeconds,
    AltitudeViewMode? currentViewMode, // 🔥 Afegit al copyWith
  }) {
    return AlarmSettings(
      distanceEnabled: distanceEnabled ?? this.distanceEnabled,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      accEnabled: accEnabled ?? this.accEnabled,
      accMeters: accMeters ?? this.accMeters,
      cotaEnabled: cotaEnabled ?? this.cotaEnabled,
      cotaMeters: cotaMeters ?? this.cotaMeters,
      timeEnabled: timeEnabled ?? this.timeEnabled,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      currentViewMode:
          currentViewMode ?? this.currentViewMode, // 🔥 Afegit aquí
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

  bool _anyEnabled(AlarmSettings s) {
    return s.distanceEnabled || s.accEnabled || s.cotaEnabled || s.timeEnabled;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Llegim l'index de l'enum (0 per desnivell, 1 per cotes)
    final viewIndex = prefs.getInt('alarm_altitude_view_mode') ?? 0;
    final savedViewMode = AltitudeViewMode
        .values[viewIndex.clamp(0, AltitudeViewMode.values.length - 1)];

    state = AlarmSettings(
      distanceEnabled: prefs.getBool('alarm_distance_enabled') ?? false,
      distanceMeters: prefs.getDouble('alarm_distance_meters') ?? 100.0,
      accEnabled: prefs.getBool('alarm_acc_enabled') ?? false,
      accMeters: prefs.getDouble('alarm_acc_meters') ?? 100.0,
      cotaEnabled: prefs.getBool('alarm_cota_enabled') ?? false,
      cotaMeters: prefs.getDouble('alarm_cota_meters') ?? 500.0,
      timeEnabled: prefs.getBool('alarm_time_enabled') ?? false,
      timeSeconds: prefs.getInt('alarm_time_seconds') ?? 60,
      currentViewMode: savedViewMode,
    );

    if (_anyEnabled(state)) {
      await ref.read(alarmEngineProvider).start();
    }
  }

  // Guardem la configuració i també si cada alarma està activa.
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_distance_enabled', state.distanceEnabled);
    await prefs.setDouble('alarm_distance_meters', state.distanceMeters);
    await prefs.setBool('alarm_acc_enabled', state.accEnabled);
    await prefs.setDouble('alarm_acc_meters', state.accMeters);
    await prefs.setBool('alarm_cota_enabled', state.cotaEnabled);
    await prefs.setDouble('alarm_cota_meters', state.cotaMeters);
    await prefs.setBool('alarm_time_enabled', state.timeEnabled);
    await prefs.setInt('alarm_time_seconds', state.timeSeconds);
    await prefs.setInt('alarm_altitude_view_mode', state.currentViewMode.index);
  }

  void _handleEngineTransition(bool before, bool after) {
    final engine = ref.read(alarmEngineProvider);
    if (!before && after) {
      engine.start();
    } else if (before && !after)
      engine.stop();
  }

  // --- SETTERS ---

  void setDistanceAlarm(bool enabled, double meters) {
    final before = _anyEnabled(state);
    state = state.copyWith(distanceEnabled: enabled, distanceMeters: meters);
    _saveToPrefs();
    _handleEngineTransition(before, _anyEnabled(state));
  }

  void setAccAlarm(bool enabled, double meters) {
    final before = _anyEnabled(state);
    final wasActive = state.accEnabled; // Guardem si ja estava activa

    state = state.copyWith(accEnabled: enabled, accMeters: meters);
    _saveToPrefs();

    // 🔥 Millora: Si el valor ha canviat i l'alarma ja estava activa,
    // reiniciem el motor per netejar els acumuladors vells
    if (wasActive && enabled) {
      ref.read(alarmEngineProvider).stop();
      ref.read(alarmEngineProvider).start();
    } else {
      _handleEngineTransition(before, _anyEnabled(state));
    }
  }

  void setCotaAlarm(bool enabled, double meters) {
    final before = _anyEnabled(state);
    final wasActive = state.cotaEnabled;

    state = state.copyWith(cotaEnabled: enabled, cotaMeters: meters);
    _saveToPrefs();

    if (wasActive && enabled) {
      ref.read(alarmEngineProvider).stop();
      ref.read(alarmEngineProvider).start();
    } else {
      _handleEngineTransition(before, _anyEnabled(state));
    }
  }

  void setTimeAlarm(bool enabled, int seconds) {
    final before = _anyEnabled(state);
    state = state.copyWith(timeEnabled: enabled, timeSeconds: seconds);
    _saveToPrefs();
    _handleEngineTransition(before, _anyEnabled(state));
  }

  void setAltitudeViewMode(AltitudeViewMode mode) {
    state = state.copyWith(currentViewMode: mode);
    _saveToPrefs(); // Guardem la preferència visual
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
