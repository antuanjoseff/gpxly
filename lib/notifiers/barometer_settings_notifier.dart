import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Definim l'estat (simple o complex segons vulguis)
class BarometerSettingsState {
  final int calibrationInterval;
  final bool isInitialized; // Per saber si ja hem llegit del disc

  BarometerSettingsState({
    required this.calibrationInterval,
    this.isInitialized = false,
  });

  BarometerSettingsState copyWith({
    int? calibrationInterval,
    bool? isInitialized,
  }) {
    return BarometerSettingsState(
      calibrationInterval: calibrationInterval ?? this.calibrationInterval,
      isInitialized: isInitialized ?? this.isInitialized,
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
    final prefs = await SharedPreferences.getInstance();
    final savedInterval = prefs.getInt(_prefKey) ?? 5;
    state = state.copyWith(
      calibrationInterval: savedInterval,
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
