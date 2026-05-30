// lib/core/altitude/altitude_processor.dart
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AltitudeState {
  final double? gps;
  final double? baro;
  final double? dem;
  final double? fused;

  const AltitudeState({this.gps, this.baro, this.dem, this.fused});

  AltitudeState copyWith({
    double? gps,
    double? baro,
    double? dem,
    double? fused,
  }) {
    return AltitudeState(
      gps: gps ?? this.gps,
      baro: baro ?? this.baro,
      dem: dem ?? this.dem,
      fused: fused ?? this.fused,
    );
  }
}

final altitudeProcessorProvider =
    NotifierProvider<AltitudeProcessor, AltitudeState>(AltitudeProcessor.new);

class AltitudeProcessor extends Notifier<AltitudeState> {
  double? _lastFused;
  double?
  _lastBaroAltCalculated; // Guarda estrictamente la última altura barométrica en metros

  final double _kCalibrate = 0.02;

  @override
  AltitudeState build() => const AltitudeState();

  void updateGps(double value) => state = state.copyWith(gps: value);
  void updateDem(double value) => state = state.copyWith(dem: value);

  // El barómetro solo normaliza la unidad y actualiza el estado en RAM.
  // Ya no toca variables de fusión globales, eliminando de raíz las corrupciones de memoria.
  void updateBaro(double currentBaroRawValue) {
    if (currentBaroRawValue < 300.0)
      return; // Protección contra ceros iniciales del canal

    // Convertimos de forma segura los hPa del hardware a metros teóricos estándar
    final double baroAltInMeters =
        (44330 * (1 - pow(currentBaroRawValue / 1013.25, 1 / 5.255)))
            .toDouble();

    state = state.copyWith(baro: baroAltInMeters);
  }

  // ─── 📊 EL ÚNICO MOTOR ANALÍTICO DE FUSIÓN DE ALTITUD (Al latido del GPS) ───
  double process() {
    double? gps = state.gps;
    double? baroAlt = state
        .baro; // Ya viene convertida limpiamente a metros desde el updateBaro
    double? dem = state.dem;

    if (gps == null || gps <= 0 || gps > 9000) {
      gps = _lastFused ?? 0.0;
    }

    // 🛑 ESCUT CRÍTIC DE ARRANQUE: Si el mapa digital aún no ha respondido,
    // esperamos congelados para no contaminar el inicio con el error del GPS de ciudad.
    if (dem == null || dem <= 0) {
      return _lastFused ?? gps;
    }

    // Calculamos la base real inalterable del relieve del terreno
    final double referenceBaseAlt = (gps * 0.3) + (dem * 0.7);

    // ─── 🏁 EL BAUTISMO INICIAL (Se ejecuta una sola vez en la ruta) ───
    if (_lastFused == null) {
      _lastFused = referenceBaseAlt;
      if (baroAlt != null)
        _lastBaroAltCalculated = baroAlt; // Sincronización en metros impecable

      print(
        "🎯 [ALTITUDE] Calibración QNH inicial completada con éxito: ${_lastFused!.toStringAsFixed(1)}m",
      );
      state = state.copyWith(fused: _lastFused);
      return _lastFused!;
    }

    // ─── 🏃 BUCLE DE SEGUIMIENTO EN RUTA (Cálculo de Deltas Relativos) ───
    if (baroAlt != null && _lastBaroAltCalculated != null) {
      // Calculamos la diferencia neta de metros de presión real respecto al punto anterior
      double deltaMetresBaro = baroAlt - _lastBaroAltCalculated!;

      // Escut de Threshold contra ráfagas de viento fuertes junto al río Ter
      if (deltaMetresBaro.abs() > 4.0) {
        deltaMetresBaro = deltaMetresBaro.isNegative ? -2.5 : 2.5;
      }

      // Hacemos avanzar la altitud fused sumando el cambio de presión física real
      double fused = _lastFused! + deltaMetresBaro;

      // El Filtro Complementario corrige de fondo la deriva meteorológica absorbiendo el error
      fused = (fused * (1 - _kCalibrate)) + (referenceBaseAlt * _kCalibrate);

      _lastFused = fused;
      _lastBaroAltCalculated =
          baroAlt; // Guardamos la referencia limpia para la siguiente iteración
    } else {
      // Fallback si el móvil no tuviera barómetro físico
      _lastFused = (_lastFused! * 0.8) + (referenceBaseAlt * 0.2);
      if (baroAlt != null) _lastBaroAltCalculated = baroAlt;
    }

    state = state.copyWith(fused: _lastFused);
    return _lastFused!;
  }

  void reset() {
    _lastFused = null;
    _lastBaroAltCalculated = null;
    state = const AltitudeState();
  }
}
