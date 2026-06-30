import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/elevation_range_notifier.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1 [INDEX]
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/utils/geo_utils.dart';
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

    // 🔥 NOVA VELOCITAT ESTABLE
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

      // 🔥 SUBSTITUCIÓ DEL CÀLCUL ANTIC DE VELOCITAT
      final gps = ref.read(gpsSettingsProvider);

      if (gps.useTime) {
        currentSpeedKmh = _computeSpeedWithTimeWindow(state.points, gps);
      } else {
        currentSpeedKmh = _computeSpeedWithDistanceWindow(state.points, gps);
      }

      final double diffAlt = newPoint.altitude - lastPoint.altitude;
      if (diffAlt > 0.5) {
        newAscent += diffAlt;
      } else if (diffAlt < -0.5) {
        newDescent += diffAlt.abs();
      }
    }

    if (state.points.isEmpty || newPoint.altitude > newMax) {
      newMax = newPoint.altitude;
    }
    if (state.points.isEmpty || newPoint.altitude < newMin) {
      newMin = newPoint.altitude;
    }

    if (currentSpeedKmh.isNegative || currentSpeedKmh > 120.0 || _isStopped) {
      currentSpeedKmh = 0.0;
    }

    final Duration totalDuration = ref.read(timerProvider);
    final Duration movingDuration = totalDuration - stoppedDuration;
    double newAvgSpeed = 0.0;
    double newAvgSpeedTotal = 0.0;

    final double distanceKm = newDistance / 1000.0;

    if (movingDuration.inSeconds > 5 && newDistance > 0) {
      final double timeHours = movingDuration.inSeconds / 3600.0;
      newAvgSpeed = distanceKm / timeHours;
    }

    if (totalDuration.inSeconds > 5 && newDistance > 0) {
      final double timeHoursTotal = totalDuration.inSeconds / 3600.0;
      newAvgSpeedTotal = distanceKm / timeHoursTotal;
    }

    if (currentSpeedKmh > newMaxSpeed &&
        currentSpeedKmh < 120.0 &&
        !_isStopped) {
      newMaxSpeed = currentSpeedKmh;
    }

    final userPositionWithDistance = newPoint.copyWith(
      distanceAtPoint: calculatedDistanceAtPoint,
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
      currentSpeed: currentSpeedKmh,
    );

    ref
        .read(elevationRangeProvider.notifier)
        .updateWithNewAltitude(newPoint.altitude);

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

  List<UserPosition> _filterPointsByAccuracy(List<UserPosition> points) {
    if (points.length < 2) return points;

    final filtered = <UserPosition>[];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      // Punt massa imprecís
      if (p.accuracy > 15.0) continue;

      // Segment massa sorollós
      if (i > 0) {
        final prev = points[i - 1];

        final step = distanceBetween(
          prev.position.latitude,
          prev.position.longitude,
          p.position.latitude,
          p.position.longitude,
        );

        final acc = prev.accuracy + p.accuracy;
        if (step < acc) continue;
      }

      filtered.add(p);
    }

    return filtered;
  }

  double _computeSpeedWithTimeWindow(
    List<UserPosition> points,
    GpsSettings gps,
  ) {
    if (points.length < 2) return 0.0;

    final filtered = _filterPointsByAccuracy(points);
    if (filtered.length < 2) return 0.0;

    final windowSeconds = TrackThresholds.minSpeedWindowSeconds;

    final List<UserPosition> window = [];
    final last = filtered.last;
    window.add(last);

    for (int i = filtered.length - 2; i >= 0; i--) {
      final p = filtered[i];
      final dt = last.timestamp.difference(p.timestamp).inSeconds;

      if (dt >= windowSeconds) {
        window.add(p);
        break;
      }

      window.add(p);
    }

    if (window.length < 2) return 0.0;

    final first = window.last;

    final dist = distanceBetween(
      first.position.latitude,
      first.position.longitude,
      last.position.latitude,
      last.position.longitude,
    );

    final dt =
        last.timestamp.difference(first.timestamp).inMilliseconds / 1000.0;

    if (dt <= 0.0) return 0.0;

    final speedMs = dist / dt;
    return speedMs * 3.6;
  }

  double _computeSpeedWithDistanceWindow(
    List<UserPosition> points,
    GpsSettings gps,
  ) {
    if (points.length < 2) return 0.0;

    final filtered = _filterPointsByAccuracy(points);
    if (filtered.length < 2) return 0.0;

    final minMeters = TrackThresholds.minSpeedWindowMeters;

    final List<UserPosition> window = [];
    final last = filtered.last;
    window.add(last);

    double accumulated = 0.0;

    for (int i = filtered.length - 2; i >= 0; i--) {
      final p = filtered[i];

      final step = distanceBetween(
        p.position.latitude,
        p.position.longitude,
        window.last.position.latitude,
        window.last.position.longitude,
      );

      accumulated += step;
      window.add(p);

      if (accumulated >= minMeters) break;
    }

    if (window.length < 2) return 0.0;

    final first = window.last;

    final dist = distanceBetween(
      first.position.latitude,
      first.position.longitude,
      last.position.latitude,
      last.position.longitude,
    );

    final dt =
        last.timestamp.difference(first.timestamp).inMilliseconds / 1000.0;

    if (dt <= 0.0) return 0.0;

    final speedMs = dist / dt;
    return speedMs * 3.6;
  }
}

// Proveïdor centralitzat de la gravació
final trackRecordingProvider = NotifierProvider<RecordingNotifier, Track>(() {
  return RecordingNotifier();
});
