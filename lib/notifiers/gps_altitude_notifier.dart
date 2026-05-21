import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🔥 Importamos el provider de ajustes para leer los minutos del slider
import 'package:senda/notifiers/barometer_settings_notifier.dart';
import 'package:senda/services/native_barometer_channel.dart';

class GpsAltitudeNotifier extends Notifier<double> {
  double _lastBaroAlt = 0.0;
  double _offset = 0.0;
  bool _hasBarometer = false;

  // 🔥 Nuevo: Control para evitar mostrar altitudes negativas al arrancar
  bool _isCalibrated = false;

  DateTime? _lastCalibrationTime;

  // ⚙️ Configuración
  final double _minAccuracyRequired = 15.0;
  final double _pressureJumpThreshold = 2.0;

  @override
  double build() {
    NativeBarometerChannel.pressureStream().listen((pressure) {
      _hasBarometer = true;
      double newBaroAlt = _pressureToAltitude(pressure);

      if ((newBaroAlt - _lastBaroAlt).abs() > _pressureJumpThreshold) {
        _lastCalibrationTime = null;
      }

      _lastBaroAlt = newBaroAlt;
      _updateState();
    });

    return 0.0;
  }

  // 🔥 Getter para que la UI sepa si mostrar "--m" o el número real
  bool get isCalibrated => _isCalibrated;

  void update(double cogValue, {required double horizontalAccuracy}) {
    final now = DateTime.now();

    // 🔥 LEEMOS EL INTERVALO real que el usuario ha puesto en el Slider
    final settings = ref.read(barometerSettingsProvider);
    final calibrationInterval = Duration(minutes: settings.calibrationInterval);

    bool intervalPassed =
        _lastCalibrationTime == null ||
        now.difference(_lastCalibrationTime!) > calibrationInterval;

    bool hasGoodCoverage = horizontalAccuracy <= _minAccuracyRequired;

    if (_hasBarometer && intervalPassed && hasGoodCoverage) {
      forceCalibration(cogValue);
    }

    if (!_hasBarometer) {
      state = cogValue;
    } else {
      _updateState();
    }
  }

  void forceCalibration(double cogValue) {
    _offset = cogValue - _lastBaroAlt;
    _lastCalibrationTime = DateTime.now();
    _isCalibrated = true; // 🔥 Marcamos que el sistema ya es fiable
    _updateState();
    print("🎯 CALIBRAT: Nou offset $_offset");
  }

  void _updateState() {
    if (_hasBarometer) {
      // NOMÉS actualitzem l'estat si ja hem calibrat almenys un cop.
      // Si no, mantenim l'estat en 0.0 (que la UI convertirà en --m)
      if (_isCalibrated) {
        state = _lastBaroAlt + _offset;
      } else {
        state = 0.0;
      }
    }
  }

  double _pressureToAltitude(double p) =>
      44330.0 * (1.0 - pow(p / 1013.25, 0.1903));
}

final gpsAltitudeProvider = NotifierProvider<GpsAltitudeNotifier, double>(
  GpsAltitudeNotifier.new,
);
