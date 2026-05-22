import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Definim l'estat (simple o complex segons vulguis)
class BarometerSettingsState {
  final int calibrationInterval;
  final bool isInitialized; // Per saber si ja hem llegit del disc
  final bool hasBarometer;

  BarometerSettingsState({
    required this.calibrationInterval,
    this.isInitialized = false,
    this.hasBarometer = true,
  });

  BarometerSettingsState copyWith({
    int? calibrationInterval,
    bool? isInitialized,
    bool? hasBarometer,
  }) {
    return BarometerSettingsState(
      calibrationInterval: calibrationInterval ?? this.calibrationInterval,
      isInitialized: isInitialized ?? this.isInitialized,
      hasBarometer: hasBarometer ?? this.hasBarometer,
    );
  }
}

// 2. El Notifier amb la sintaxi moderna
class BarometerSettingsNotifier extends Notifier<BarometerSettingsState> {
  static const _prefKey = 'baro_calibration_interval';

  @override
  BarometerSettingsState build() {
    // Estat inicial per defecte (5 minuts)
    _loadSettings();
    return BarometerSettingsState(calibrationInterval: 5);
  }

  // Càrrega asíncrona des del disc
  Future<void> _loadSettings() async {
    final hasBaro = await NativeBarometerChannel.hasBarometer();

    final prefs = await SharedPreferences.getInstance();
    final savedInterval = prefs.getInt(_prefKey) ?? 5;

    state = state.copyWith(
      calibrationInterval: savedInterval,
      hasBarometer: hasBaro,
      isInitialized: true,
    );
  }

  // Mètode per actualitzar l'interval (el que cridarà el Slider)
  Future<void> setInterval(int minutes) async {
    state = state.copyWith(calibrationInterval: minutes);

    // Persistència asíncrona (fire and forget o await)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, minutes);
  }
}

// 3. El provider global
final barometerSettingsProvider =
    NotifierProvider<BarometerSettingsNotifier, BarometerSettingsState>(
      BarometerSettingsNotifier.new,
    );
