import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/notifiers/elevation_range_notifier.dart';
import 'package:strack_rec/notifiers/location_notifier.dart'; // Bloc 1 [INDEX]
import 'package:strack_rec/notifiers/timer_notifier.dart';
import 'package:strack_rec/services/altitude_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingNotifier extends Notifier<Track> {
  // Gestió de temps aturat mantinguda intacta [INDEX]
  Duration _stoppedDuration = Duration.zero;
  DateTime? _stopStart;
  bool _isStopped = false;
  Timer? _gpsTimeoutTimer;
  final List<_SpeedSample> _recentSpeedSamples = <_SpeedSample>[];
  final List<_SpeedSample> _sustainedSpeedSamples = <_SpeedSample>[];
  double _speedSum = 0.0;
  int _speedCount = 0;
  double _movingSpeedSum = 0.0;
  int _movingSpeedCount = 0;
  double? _lastElevationForGain;

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

  void _addProcessedPoint(UserPosition newPoint) {
    final processingStopwatch = Stopwatch()..start();
    _gpsTimeoutTimer?.cancel();
    _updateStopTime(newPoint.speed, newPoint.timestamp);

    _gpsTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (state.recordingState == RecordingState.recording && !_isStopped) {
        _stopStart = DateTime.now();
        _isStopped = true;

        state = state.copyWith(
          stats: state.stats.copyWith(stoppedDuration: stoppedDuration),
        );
      }
    });

    double newDistance = state.stats.distance;
    double newAscent = state.stats.ascent;
    double newDescent = state.stats.descent;
    double newMax = state.stats.maxElevation;
    double newMin = state.stats.minElevation;
    double newMaxSpeed = state.stats.maxSpeed;

    double calculatedDistanceAtPoint = newDistance;
    double currentSpeedKmh = 0.0;

    if (state.points.isNotEmpty) {
      final lastPoint = state.points.last;

      final double step = Geolocator.distanceBetween(
        lastPoint.position.latitude,
        lastPoint.position.longitude,
        newPoint.position.latitude,
        newPoint.position.longitude,
      );

      if (step.isFinite && step < 200) {
        newDistance += step;
        calculatedDistanceAtPoint = newDistance;
      }

      final int timeDiffMs = newPoint.timestamp
          .difference(lastPoint.timestamp)
          .inMilliseconds;
      final double timeDiffSeconds = timeDiffMs / 1000.0;

      if (timeDiffSeconds > 0.0 && step.isFinite && step > 0.2) {
        final rawSpeedKmh = (step / timeDiffSeconds) * 3.6;
        _recentSpeedSamples.add(
          _SpeedSample(timestamp: newPoint.timestamp, speed: rawSpeedKmh),
        );
        if (_recentSpeedSamples.length > Track.smoothedSpeedWindow) {
          _recentSpeedSamples.removeAt(0);
        }
      }

      if (_recentSpeedSamples.isNotEmpty) {
        currentSpeedKmh =
            _recentSpeedSamples
                .map((sample) => sample.speed)
                .reduce((sum, speed) => sum + speed) /
            _recentSpeedSamples.length;
      }
    }

    final lastElevation = _lastElevationForGain;
    if (lastElevation != null) {
      final elevationDelta = newPoint.altitude - lastElevation;
      if (elevationDelta.abs() >= 3.5) {
        if (elevationDelta > 0.0) {
          newAscent += elevationDelta;
        } else {
          newDescent += elevationDelta.abs();
        }
        _lastElevationForGain = newPoint.altitude;
      }
    } else {
      _lastElevationForGain = newPoint.altitude;
    }

    if (state.points.isEmpty || newPoint.altitude > newMax) {
      newMax = newPoint.altitude;
    }
    if (state.points.isEmpty || newPoint.altitude < newMin) {
      newMin = newPoint.altitude;
    }

    // Filtre protector per a salts geomètrics absurds o rebots de satèl·lits
    if (currentSpeedKmh.isNegative || currentSpeedKmh > 130.0 || _isStopped) {
      currentSpeedKmh = 0.0;
    }

    final currentSpeedSample = _SpeedSample(
      timestamp: newPoint.timestamp,
      speed: currentSpeedKmh,
    );
    _sustainedSpeedSamples.add(currentSpeedSample);
    while (_sustainedSpeedSamples.length > 1 &&
        newPoint.timestamp
                .difference(_sustainedSpeedSamples.first.timestamp)
                .inSeconds >
            10) {
      _sustainedSpeedSamples.removeAt(0);
    }
    if (_sustainedSpeedSamples.length > 1 &&
        newPoint.timestamp
                .difference(_sustainedSpeedSamples.first.timestamp)
                .inSeconds >=
            10) {
      final sustainedSpeed =
          _sustainedSpeedSamples
              .map((sample) => sample.speed)
              .reduce((sum, speed) => sum + speed) /
          _sustainedSpeedSamples.length;
      if (sustainedSpeed > newMaxSpeed) newMaxSpeed = sustainedSpeed;
    }

    final Duration totalDuration = ref.read(timerProvider);
    _speedSum += currentSpeedKmh;
    _speedCount += 1;
    if (currentSpeedKmh > 0.0) {
      _movingSpeedSum += currentSpeedKmh;
      _movingSpeedCount += 1;
    }
    final double newAvgSpeed = _movingSpeedCount == 0
        ? 0.0
        : _movingSpeedSum / _movingSpeedCount;
    final double newAvgSpeedTotal = _speedCount == 0
        ? 0.0
        : _speedSum / _speedCount;

    final userPositionWithDistance = newPoint.copyWith(
      distanceAtPoint: calculatedDistanceAtPoint,
      speed: currentSpeedKmh,
    );

    final updatedStats = state.stats.copyWith(
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
      stoppedDuration: stoppedDuration,
      duration: totalDuration,
      averageSpeed: newAvgSpeed,
      averageSpeedTotal: newAvgSpeedTotal,
      maxSpeed: newMaxSpeed,
    );

    state = state.copyWith(
      points: [...state.points, userPositionWithDistance],
      stats: updatedStats,
      currentSpeed:
          currentSpeedKmh, // La UI rep directament el valor del darrer segon estable
    );

    ref
        .read(elevationRangeProvider.notifier)
        .updateWithNewAltitude(newPoint.altitude);

    if (state.points.length % 10 == 0) {
      _autoSaveToPrefs();

      processingStopwatch.stop();
      AltitudeLoggerService().log(
        'TRACK PROCESS -> points=${state.points.length} '
        'elapsed=${processingStopwatch.elapsedMilliseconds}ms '
        'distance=${state.stats.distance.toStringAsFixed(1)}m '
        'ascent=${state.stats.ascent.toStringAsFixed(1)}m '
        'speed=${state.currentSpeed.toStringAsFixed(1)}km/h',
      );
    } else if (processingStopwatch.elapsedMilliseconds >= 200) {
      processingStopwatch.stop();
      AltitudeLoggerService().log(
        'TRACK SLOW PROCESS -> points=${state.points.length} '
        'elapsed=${processingStopwatch.elapsedMilliseconds}ms',
      );
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
      _rebuildIncrementalState(loadedPoints);

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
    _resetIncrementalState();

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

  Future<void> reset() async {
    _gpsTimeoutTimer?.cancel();
    _resetIncrementalState();
    state = Track(
      points: const [],
      recordingState: RecordingState.idle,
      stats: TrackStats(),
    );
    await clearCache();
  }

  void _resetIncrementalState() {
    _recentSpeedSamples.clear();
    _sustainedSpeedSamples.clear();
    _speedSum = 0.0;
    _speedCount = 0;
    _movingSpeedSum = 0.0;
    _movingSpeedCount = 0;
    _lastElevationForGain = null;
  }

  void _rebuildIncrementalState(List<UserPosition> points) {
    _resetIncrementalState();
    for (final point in points) {
      _lastElevationForGain = point.altitude;
      _speedSum += point.speed;
      _speedCount += 1;
      if (point.speed > 0.0) {
        _movingSpeedSum += point.speed;
        _movingSpeedCount += 1;
      }
    }

    for (final point
        in points.reversed.take(Track.smoothedSpeedWindow).toList().reversed) {
      _recentSpeedSamples.add(
        _SpeedSample(timestamp: point.timestamp, speed: point.speed),
      );
    }

    final latestTimestamp = points.isEmpty ? null : points.last.timestamp;
    if (latestTimestamp == null) return;
    for (final point in points.reversed) {
      if (latestTimestamp.difference(point.timestamp).inSeconds > 10) break;
      _sustainedSpeedSamples.insert(
        0,
        _SpeedSample(timestamp: point.timestamp, speed: point.speed),
      );
    }
  }
}

class _SpeedSample {
  const _SpeedSample({required this.timestamp, required this.speed});

  final DateTime timestamp;
  final double speed;
}

// Proveïdor centralitzat de la gravació
final trackRecordingProvider = NotifierProvider<RecordingNotifier, Track>(() {
  return RecordingNotifier();
});
