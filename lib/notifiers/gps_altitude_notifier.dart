import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/notifiers/barometer_settings_notifier.dart';
import 'package:strack_rec/services/altitude_logger.dart';
import 'package:strack_rec/services/native_barometer_channel.dart';

class GpsAltitudeNotifier extends Notifier<double> {
  double _lastBaroAlt = 0.0;
  double _offset = 0.0;
  bool _hasBarometer = false;
  bool isSimulating = false;
  bool _isCalibrated = false;

  DateTime? _lastCalibrationTime;

  final double _minAccuracyRequired = 15.0;
  final double _pressureJumpThreshold = 2.0;

  @override
  double build() {
    NativeBarometerChannel.pressureStream().listen((pressure) {
      _hasBarometer = true;
      double newBaroAlt = _pressureToAltitude(pressure);

      // Si hi ha un salt de pressió brusc, invalidem calibratge
      if ((newBaroAlt - _lastBaroAlt).abs() > _pressureJumpThreshold) {
        _lastCalibrationTime = null;
        _isCalibrated = false;
        AltitudeLoggerService().log(
          "🚨 BARÒMETRE -> Descalibrat per salt de pressió! (Salt de ${(newBaroAlt - _lastBaroAlt).abs().toStringAsFixed(1)}m)",
        );
      }

      _lastBaroAlt = newBaroAlt;
      // 🚩 NO cridem a _updateState() aquí per no bombardejar l'AlarmEngine
    });

    return 0.0;
  }

  bool get isCalibrated => _isCalibrated;

  /// Aquest mètode s'executa 1:1 amb cada coordenada del GPS
  void update(double gpsAlt, {required double horizontalAccuracy}) {
    if (isSimulating) {
      _isCalibrated = true;
      state = gpsAlt;
      return;
    }

    final now = DateTime.now();
    final settings = ref.read(barometerSettingsProvider);
    final calibrationInterval = Duration(minutes: settings.calibrationInterval);

    bool intervalPassed =
        _lastCalibrationTime == null ||
        now.difference(_lastCalibrationTime!) > calibrationInterval;

    bool hasGoodCoverage = horizontalAccuracy <= _minAccuracyRequired;

    // 1. Decidim si cal recalibrar l'offset
    if (_hasBarometer && intervalPassed && hasGoodCoverage) {
      _offset = gpsAlt - _lastBaroAlt;
      _lastCalibrationTime = now;
      _isCalibrated = true;
      AltitudeLoggerService().log(
        "🎯 CALIBRATGE -> Nou offset: ${_offset.toStringAsFixed(1)}m (GPS: ${gpsAlt.toStringAsFixed(1)}m | BaroPuru: ${_lastBaroAlt.toStringAsFixed(1)}m)",
      );
    }

    // 2. ACTUALITZEM L'ESTAT (Això dispara l'AlarmEngine un sol cop)
    if (_hasBarometer && _isCalibrated) {
      state = _lastBaroAlt + _offset;
    } else {
      state =
          gpsAlt; // Fallback directe al GPS si no hi ha baròmetre o calibratge
    }
  }

  void forceCalibration(double gpsAlt) {
    _offset = gpsAlt - _lastBaroAlt;
    _lastCalibrationTime = DateTime.now();
    _isCalibrated = true;
    state = _lastBaroAlt + _offset;
  }

  double _pressureToAltitude(double p) =>
      44330.0 * (1.0 - pow(p / 1013.25, 0.1903));
}

final gpsAltitudeProvider = NotifierProvider<GpsAltitudeNotifier, double>(
  GpsAltitudeNotifier.new,
);
