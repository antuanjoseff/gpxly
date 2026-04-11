import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsSettings {
  final bool useTime;
  final int seconds;
  final double meters;
  final double accuracy;

  GpsSettings({
    required this.useTime,
    required this.seconds,
    required this.meters,
    required this.accuracy,
  });

  GpsSettings copyWith({
    bool? useTime,
    int? seconds,
    double? meters,
    double? accuracy,
  }) {
    return GpsSettings(
      useTime: useTime ?? this.useTime,
      seconds: seconds ?? this.seconds,
      meters: meters ?? this.meters,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}

class GpsSettingsNotifier extends Notifier<GpsSettings> {
  static const int minSeconds = 1;
  static const double minMeters = 1.0;

  @override
  GpsSettings build() {
    final initial = GpsSettings(
      useTime: true,
      seconds: 5,
      meters: 10,
      accuracy: 30,
    );

    _loadFromPrefs();
    return initial;
  }

  // -----------------------------
  // LOAD
  // -----------------------------
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final useTime = prefs.getBool('gps_useTime');
    final seconds = prefs.getInt('gps_seconds');
    final meters = prefs.getDouble('gps_meters');
    final accuracy = prefs.getDouble('gps_accuracy');

    state = state.copyWith(
      useTime: useTime ?? state.useTime,
      seconds: seconds ?? state.seconds,
      meters: meters ?? state.meters,
      accuracy: accuracy ?? state.accuracy,
    );
  }

  // -----------------------------
  // SAVE (només guarda, NO envia al nadiu)
  // -----------------------------
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('gps_useTime', state.useTime);
    await prefs.setInt('gps_seconds', state.seconds);
    await prefs.setDouble('gps_meters', state.meters);
    await prefs.setDouble('gps_accuracy', state.accuracy);
  }

  // -----------------------------
  // UPDATE METHODS (només estat + prefs)
  // -----------------------------
  void setUseTime(bool value) {
    if (value) {
      state = state.copyWith(useTime: true, meters: minMeters);
    } else {
      state = state.copyWith(useTime: false, seconds: minSeconds);
    }
    _saveToPrefs();
  }

  void setSeconds(int value) {
    state = state.copyWith(seconds: value < minSeconds ? minSeconds : value);
    _saveToPrefs();
  }

  void setMeters(double value) {
    state = state.copyWith(meters: value < minMeters ? minMeters : value);
    _saveToPrefs();
  }

  void setAccuracy(double value) {
    state = state.copyWith(accuracy: value);
    _saveToPrefs();
  }

  // -----------------------------
  // APPLY (l’únic que envia al nadiu)
  // -----------------------------
  Future<void> apply() async {
    await _saveToPrefs();

    await NativeGpsChannel.start(
      useTime: state.useTime,
      seconds: state.seconds,
      meters: state.meters,
      accuracy: state.accuracy,
    );
  }
}

final gpsSettingsProvider = NotifierProvider<GpsSettingsNotifier, GpsSettings>(
  GpsSettingsNotifier.new,
);
