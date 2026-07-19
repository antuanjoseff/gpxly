import 'dart:async';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/services/native_gps_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsSettings {
  final bool useTime;
  final int seconds;
  final double meters;
  final double accuracy;
  final bool isFollowing;

  GpsSettings({
    required this.useTime,
    required this.seconds,
    required this.meters,
    required this.accuracy,
    required this.isFollowing,
  });

  GpsSettings copyWith({
    bool? useTime,
    int? seconds,
    double? meters,
    double? accuracy,
    bool? isFollowing,
  }) {
    return GpsSettings(
      useTime: useTime ?? this.useTime,
      seconds: seconds ?? this.seconds,
      meters: meters ?? this.meters,
      accuracy: accuracy ?? this.accuracy,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class GpsSettingsNotifier extends Notifier<GpsSettings> {
  static const int minSeconds = 1;
  static const double minMeters = 1.0;

  // 🎯 El "pany" per saber quan hem acabat de llegir del disc
  final Completer<void> _initialized = Completer<void>();
  Future<void> get initialized => _initialized.future;

  @override
  GpsSettings build() {
    // Valors "falsos" temporals mentre carreguem
    final initial = GpsSettings(
      useTime: false,
      seconds: 5,
      meters: 5,
      accuracy: 30,
      isFollowing: false,
    );

    // Iniciem la càrrega asíncrona
    _init();

    return initial;
  }

  Future<void> _init() async {
    await _loadFromPrefs();
    // Marquem com a llest perquè el TrackNotifier pugui avançar
    if (!_initialized.isCompleted) _initialized.complete();
  }

  void setFollowing(bool value) {
    state = state.copyWith(isFollowing: value);

    if (value) {
      // Mode seguiment: GPS cada 2s
      state = state.copyWith(useTime: true, seconds: 2, meters: 0);
    }

    apply();
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

    double metersFiltrat = meters ?? 5.0;
    bool useTimeFiltrat = useTime ?? false;

    if (meters == 10.0) {
      metersFiltrat = 5.0;
      useTimeFiltrat = false;

      // Ho guardem immediatament a disc perquè quedi fixat per a les properes vegades
      await prefs.setBool('gps_useTime', false);
      await prefs.setDouble('gps_meters', 5.0);
    }

    state = state.copyWith(
      useTime: useTimeFiltrat,
      seconds: seconds ?? state.seconds,
      meters: metersFiltrat,
      accuracy: accuracy ?? state.accuracy,
    );
  }

  // -----------------------------
  // SAVE
  // -----------------------------
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gps_useTime', state.useTime);
    await prefs.setInt('gps_seconds', state.seconds);
    await prefs.setDouble('gps_meters', state.meters);
    await prefs.setDouble('gps_accuracy', state.accuracy);
  }

  // -----------------------------
  // UPDATE METHODS
  // -----------------------------
  void setUseTime(bool value) {
    state = value
        ? state.copyWith(useTime: true, meters: minMeters)
        : state.copyWith(useTime: false, seconds: minSeconds);
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
  // APPLY
  // -----------------------------
  Future<void> apply() async {
    await _saveToPrefs();

    // 1. Iniciem/Actualitzem el GPS
    await NativeGpsChannel.start(
      useTime: state.useTime,
      seconds: state.seconds,
      meters: state.meters,
      accuracy: state.accuracy,
    );

    // 2. Sincronitzem el Baròmetre
    int periodUs;
    if (state.useTime) {
      // Si el GPS va per temps, posem el mateix (mínim 1s per seguretat)
      periodUs = state.seconds * 1000000;
    } else {
      // Si el GPS va per DISTÀNCIA, forcem 2 segons fixos
      periodUs = 2000000;
    }

    await NativeBarometerChannel.setSamplingPeriod(periodUs);

    // Eliminem qualsevol actualització dinàmica per velocitat
    print("📡 Baròmetre fixat a: ${periodUs / 1000000}s");
  }

  Future<void> setNavigationMode() async {
    state = state.copyWith(
      useTime: true,
      seconds: TrackThresholds.navGpsSeconds,
      meters: TrackThresholds.navGpsMeters,
      accuracy: TrackThresholds.navGpsAccuracy,
    );
    await apply();
  }

  Future<void> restoreDefaultMode() async {
    await _loadFromPrefs();
    await apply();
  }

  void updateBarometerSync(double currentSpeed) {
    // Si usem temps, el baròmetre ja es va configurar a l'apply() i no cal fer res
    if (state.useTime) return;

    int periodUs;
    if (currentSpeed > 0.5) {
      // Més de 1.8 km/h
      // temps = metres configurats / velocitat real
      double seconds = state.meters / currentSpeed;
      // Límit de seguretat entre 2s i 30s
      periodUs = (seconds.clamp(2.0, 30.0) * 1000000).toInt();
    } else {
      // Aturats: 5 segons per no saturar ni gastar
      periodUs = 5000000;
    }

    NativeBarometerChannel.setSamplingPeriod(periodUs);
  }
}

final gpsSettingsProvider = NotifierProvider<GpsSettingsNotifier, GpsSettings>(
  GpsSettingsNotifier.new,
);
