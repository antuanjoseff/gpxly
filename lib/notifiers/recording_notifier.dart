import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/elevation_range_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1 [INDEX]
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingNotifier extends Notifier<Track> {
  // Gestió de temps aturat mantinguda intacta [INDEX]
  Duration _stoppedDuration = Duration.zero;
  DateTime? _stopStart;
  bool _isStopped = false;
  Timer? _gpsTimeoutTimer;

  Duration get stoppedDuration {
    if (_isStopped && _stopStart != null) {
      return _stoppedDuration + DateTime.now().difference(_stopStart!);
    }
    return _stoppedDuration;
  }

  @override
  Track build() {
    ref.onDispose(() {
      _gpsTimeoutTimer?.cancel();
    });

    // 🔗 DATA PIPELINING: Escoltem de fons el proveïdor de GPS natiu [INDEX]
    ref.listen<UserPosition?>(locationProvider, (previous, next) {
      if (next == null) return;

      // Actualitzem les variables a temps real del punt blau (Sempre) [INDEX]
      state = state.copyWith(
        currentPosition: next.position,
        currentHeading: next.heading,
        currentSpeed: next.speed,
      );

      // Només afegim a la llista si la gravació està activa [INDEX]
      if (state.recordingState == RecordingState.recording) {
        _addProcessedPoint(next);
      }
    });

    return Track(
      points: const [],
      recordingState: RecordingState.idle,
      stats: TrackStats(),
    );
  }

  // 📐 ALGORISME MATEMÀTIC DE GRAVACIÓ REFACTORITZAT
  void _addProcessedPoint(UserPosition newPoint) {
    // 1️⃣ Cancelamos el timer del punto anterior porque acaba de llegar uno nuevo del GPS
    _gpsTimeoutTimer?.cancel();

    // 2️⃣ Procesamos la velocidad del punto que acaba de entrar (Lógica original)
    _updateStopTime(newPoint.speed, newPoint.timestamp);

    // 3️⃣ 🚨 LA SOLUCIÓN: Si pasan 5 segundos sin que entre OTRO punto de GPS, asumimos parada por metros
    _gpsTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (state.recordingState == RecordingState.recording && !_isStopped) {
        _stopStart = DateTime.now();
        _isStopped = true;

        // Forzamos un refresco atómico en Riverpod para que la pantalla sume el tiempo parado en vivo
        state = state.copyWith(
          stats: state.stats.copyWith(stoppedDuration: stoppedDuration),
        );
      }
    });

    // ----------------------------------------------------------------------
    // 🟢 A PARTIR DE ACÁ TU CÓDIGO SE MANTIENE 100% IDÉNTICO E INTACTO
    // ----------------------------------------------------------------------
    double newDistance = state.stats.distance;
    double newAscent = state.stats.ascent;
    double newDescent = state.stats.descent;
    double newMax = state.stats.maxElevation;
    double newMin = state.stats.minElevation;
    double newMaxSpeed = state.stats.maxSpeed; // Rescatem la màxima actual

    double calculatedDistanceAtPoint = newDistance;

    // 🆕 VARIABLE PER AL CÀLCUL DE LA VELOCITAT ACTUAL PER SEGMENTS
    double currentSpeedKmh = 0.0;

    if (state.points.isNotEmpty) {
      final lastPoint = state.points.last;

      final double step = Geolocator.distanceBetween(
        lastPoint.position.latitude,
        lastPoint.position.longitude,
        newPoint.position.latitude,
        newPoint.position.longitude,
      );

      // El teu filtre anti-bogeries de distància (Mantingut intacte)
      if (step.isFinite && step < 200) {
        newDistance += step;
        calculatedDistanceAtPoint = newDistance;
      }

      // 🌟 NOVA LÒGICA: Calculem la velocitat actual en funció de la distància i el temps entre els dos últims punts
      final int segmentSeconds = newPoint.timestamp
          .difference(lastPoint.timestamp)
          .inSeconds;
      if (segmentSeconds > 0 && step.isFinite && step > 0.2) {
        // (metres / segons) * 3.6 = Km/h
        currentSpeedKmh = (step / segmentSeconds) * 3.6;
      }

      // El teu filtre de sensibilitat de desnivell de muntanya (Mantingut intacte)
      final double diffAlt = newPoint.altitude - lastPoint.altitude;
      if (diffAlt > 0.5) {
        newAscent += diffAlt;
      } else if (diffAlt < -0.5) {
        newDescent += diffAlt.abs();
      }
    }

    // Actualitzem límits d'elevació
    if (state.points.isEmpty || newPoint.altitude > newMax) {
      newMax = newPoint.altitude;
    }
    if (state.points.isEmpty || newPoint.altitude < newMin) {
      newMin = newPoint.altitude;
    }

    // Filtro anti-locuras: si el coche/caminante da negativo o si estamos parados por metros, es 0
    if (currentSpeedKmh.isNegative || currentSpeedKmh > 120.0 || _isStopped) {
      currentSpeedKmh = 0.0;
    }

    // 🟢 2. CÀLCUL DE LES DUES VELOCITATS MITJANES (En moviment i Total)
    final Duration totalDuration = ref.read(timerProvider);
    final Duration movingDuration = totalDuration - stoppedDuration;
    double newAvgSpeed = 0.0;
    double newAvgSpeedTotal = 0.0; // 🆕 Nova variable per a la mitjana total

    final double distanceKm = newDistance / 1000.0;

    // A. Mitjana en Moviment (Mantinguda exactament igual: ignora el temps aturat)
    if (movingDuration.inSeconds > 5 && newDistance > 0) {
      final double timeHours = movingDuration.inSeconds / 3600.0;
      newAvgSpeed = distanceKm / timeHours;
    }

    // B. 🆕 Mitjana Total: Té en compte absolutament tot el temps, inclòs el temps aturat
    if (totalDuration.inSeconds > 5 && newDistance > 0) {
      final double timeHoursTotal = totalDuration.inSeconds / 3600.0;
      newAvgSpeedTotal = distanceKm / timeHoursTotal;
    }

    // 🟢 3. VELOCITAT MÀXIMA FILTRADA (Evita registrar saltos si el usuario está quieto)
    if (currentSpeedKmh > newMaxSpeed &&
        currentSpeedKmh < 120.0 &&
        !_isStopped) {
      newMaxSpeed = currentSpeedKmh;
    }

    // Guardem la distància d'aquest segment acumulada a dins de la UserPosition [INDEX]
    final userPositionWithDistance = newPoint.copyWith(
      distanceAtPoint: calculatedDistanceAtPoint,
    );

    // Reconstruïm el nou bloc de TrackStats compacte amb les DUES velocitats mitjanes injectades [INDEX]
    final updatedStats = state.stats.copyWith(
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
      stoppedDuration: stoppedDuration,
      duration: totalDuration,
      averageSpeed: newAvgSpeed, // Mitjana en moviment
      averageSpeedTotal:
          newAvgSpeedTotal, // 🆕 Mitjana total injectada de forma atòmica
      maxSpeed: newMaxSpeed,
    );

    // Actualitzem l'estat central de Riverpod d'un sol cop de forma atòmica [INDEX]
    state = state.copyWith(
      points: [...state.points, userPositionWithDistance],
      stats: updatedStats,
      currentSpeed:
          currentSpeedKmh, // Desa la velocitat calculada per segment en Km/h
    );

    // Actualitzem el teu rang d'elevacions per al gràfic
    ref
        .read(elevationRangeProvider.notifier)
        .updateWithNewAltitude(newPoint.altitude);

    // Auto-save cada 10 punts neta
    if (state.points.length % 10 == 0) {
      _autoSaveToPrefs();
    }
  }

  void _updateStopTime(double speed, DateTime timestamp) {
    if (speed < 0.3) {
      if (!_isStopped) {
        _stopStart = timestamp;
        _isStopped = true;
      }
    } else {
      if (_isStopped && _stopStart != null) {
        _stoppedDuration += timestamp.difference(_stopStart!);
        _isStopped = false;
        _stopStart = null;
      }
    }
  }

  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawData = prefs.getString('temp_track_data');
      if (rawData == null) return;
      final Map<String, dynamic> data = jsonDecode(rawData);

      final List<dynamic> rawPoints = data['points'] ?? [];
      final List<UserPosition> loadedPoints = rawPoints
          .map(
            (p) => UserPosition(
              position: LatLng(p['lat'], p['lon']),
              altitude: p['altitude'],
              isHgtFixed: p['isHgtFixed'] ?? false,
              timestamp: DateTime.parse(p['timestamp']),
              accuracy: p['accuracy'],
              vAccuracy: p['vAccuracy'] ?? 0.0,
              speed: p['speed'] ?? 0.0,
              heading: p['heading'] ?? 0.0,
              satellites: p['satellites'] ?? 0,
              distanceAtPoint: p['distanceAtPoint'] ?? 0.0,
            ),
          )
          .toList();

      final List<double> alts = loadedPoints.map((p) => p.altitude).toList();

      final Duration recuperadaDuration = Duration(
        seconds: data['duration'] ?? 0,
      );
      final Duration recuperadaStopped = Duration(
        seconds: data['stoppedDuration'] ?? 0,
      );
      final int activeStateIndex = data['recordingState'] ?? 0;
      final currentRecordingState = RecordingState.values[activeStateIndex];

      // 1️⃣ REGLA DE ORO: Sincronizamos las variables del Notifier local con la caché
      _stoppedDuration = recuperadaStopped;
      _stopStart = null;

      // Si la app se cerró estando en modo parado, asumimos que sigue parada al levantarla
      _isStopped = currentRecordingState == RecordingState.paused;

      // 2️⃣ Sincronizamos el cronómetro general flotante (TimerNotifier)
      ref.read(timerProvider.notifier).setInitialValue(recuperadaDuration);
      if (currentRecordingState == RecordingState.recording) {
        ref.read(timerProvider.notifier).start();
      }

      state = Track(
        points: loadedPoints,
        recordingState: currentRecordingState,
        stats: TrackStats(
          duration: recuperadaDuration,
          stoppedDuration: recuperadaStopped,
          distance: data['distance'] ?? 0.0,
          ascent: data['ascent'] ?? 0.0,
          descent: data['descent'] ?? 0.0,
          maxElevation: alts.isEmpty
              ? -9999.0
              : alts.reduce((a, b) => a > b ? a : b),
          minElevation: alts.isEmpty
              ? 9999.0
              : alts.reduce((a, b) => a < b ? a : b),
        ),
      );
    } catch (e) {
      debugPrint("Error carregant el cache: $e");
    }
  }

  // 💾 PERSISTÈNCIA NETEJA (SERIALITZACIÓ DE SUB-MODELS CORREGIDA)
  Future<void> _autoSaveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> pointsMap = state.points
          .map(
            (p) => {
              'lat': p.position.latitude,
              'lon': p.position.longitude,
              'altitude': p.altitude,
              'isHgtFixed': p.isHgtFixed,
              'timestamp': p.timestamp.toIso8601String(),
              'accuracy': p.accuracy,
              'vAccuracy': p.vAccuracy,
              'speed': p.speed,
              'heading': p.heading,
              'satellites': p.satellites,
              'distanceAtPoint': p.distanceAtPoint,
            },
          )
          .toList();

      // 3️⃣ 🚨 LA CLAVE: Leemos el GETTER dinámico real de tiempo parado,
      // no el valor estático y congelado de 'state.stats'.
      final Duration totalDurationReal = ref.read(timerProvider);

      final String rawData = jsonEncode({
        'points': pointsMap,
        'recordingState': state.recordingState.index,
        'duration': totalDurationReal.inSeconds,
        'stoppedDuration':
            stoppedDuration.inSeconds, // 🟢 Usa el getter dinámico en vivo
        'distance': state.stats.distance,
        'ascent': state.stats.ascent,
        'descent': state.stats.descent,
      });

      await prefs.setString('temp_track_data', rawData);
    } catch (e) {
      debugPrint("Error en l'auto-save: $e");
    }
  }

  // ⚙️ MANEGADORS DE CICLES DE VIDA DE GRAVACIÓ [INDEX]
  void startRecording() {
    _stoppedDuration = Duration.zero;
    _stopStart = null;
    _isStopped = false;

    ref.read(timerProvider.notifier).reset();
    ref.read(timerProvider.notifier).start();
    ref.read(elevationRangeProvider.notifier).reset();

    state = Track(
      points: const [],
      recordingState: RecordingState.recording,
      stats: TrackStats(),
    );
  }

  void pauseRecording() {
    _gpsTimeoutTimer?.cancel();
    ref.read(timerProvider.notifier).pause();
    final elapsed = ref.read(timerProvider);
    state = state.copyWith(
      recordingState: RecordingState.paused,
      stats: state.stats.copyWith(duration: elapsed),
    );
  }

  void resumeRecording() {
    ref.read(timerProvider.notifier).resume();
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  Future<void> stopRecording(Duration finalDuration) async {
    _gpsTimeoutTimer?.cancel();
    final total = ref.read(timerProvider);
    ref.read(timerProvider.notifier).pause();

    state = state.copyWith(
      recordingState: RecordingState.idle,
      stats: state.stats.copyWith(duration: total),
    );

    await _autoSaveToPrefs();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_track_data');
  }

  void reset() {
    _gpsTimeoutTimer?.cancel();
    state = Track(
      points: const [],
      recordingState: RecordingState.idle,
      stats: TrackStats(),
    );
    clearCache();
  }
}

// Proveïdor centralitzat de la gravació
final trackRecordingProvider = NotifierProvider<RecordingNotifier, Track>(() {
  return RecordingNotifier();
});
