// lib/notifiers/barometer_settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/services/native_barometer_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarometerSettingsState {
  final int calibrationInterval;
  final bool isInitialized;
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

class BarometerSettingsNotifier extends Notifier<BarometerSettingsState> {
  static const _prefKey = 'baro_calibration_interval';

  @override
  BarometerSettingsState build() {
    _loadSettings();
    return BarometerSettingsState(calibrationInterval: 5);
  }

  Future<void> _loadSettings() async {
    // ✅ MANTENIDO: Detecta de forma nativa si el teléfono tiene chip barométrico
    final hasBaro = await NativeBarometerChannel.hasBarometer();

    final prefs = await SharedPreferences.getInstance();
    final savedInterval = prefs.getInt(_prefKey) ?? 5;

    state = state.copyWith(
      calibrationInterval: savedInterval,
      hasBarometer: hasBaro,
      isInitialized: true,
    );
  }

  // ✅ BLINDADO: El método guarda el valor para la persistencia visual de la UI,
  // pero ya no dispara alertas asíncronas automáticas que puedan tumbar a cero la altitud.
  Future<void> setInterval(int minutes) async {
    state = state.copyWith(calibrationInterval: minutes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, minutes);
  }
}

final barometerSettingsProvider =
    NotifierProvider<BarometerSettingsNotifier, BarometerSettingsState>(
      BarometerSettingsNotifier.new,
    );
