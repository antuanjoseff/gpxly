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

  Duration get stoppedDuration {
    if (_isStopped && _stopStart != null) {
      return _stoppedDuration + DateTime.now().difference(_stopStart!);
    }
    return _stoppedDuration;
  }

  @override
  Track build() {
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
    _updateStopTime(newPoint.speed, newPoint.timestamp);

    double newDistance = state.stats.distance;
    double newAscent = state.stats.ascent;
    double newDescent = state.stats.descent;
    double newMax = state.stats.maxElevation;
    double newMin = state.stats.minElevation;

    double calculatedDistanceAtPoint = newDistance;

    if (state.points.isNotEmpty) {
      final lastPoint = state.points.last;

      final double step = Geolocator.distanceBetween(
        lastPoint.position.latitude,
        lastPoint.position.longitude,
        newPoint.position.latitude,
        newPoint.position.longitude,
      );

      // El teu filtre anti-bogeries de distància
      if (step.isFinite && step < 200) {
        newDistance += step;
        calculatedDistanceAtPoint = newDistance;
      }

      // El teu filtre de sensibilitat de desnivell de muntanya
      final double diffAlt = newPoint.altitude - lastPoint.altitude;
      if (diffAlt > 0.5) {
        newAscent += diffAlt;
      } else if (diffAlt < -0.5) {
        newDescent += diffAlt.abs();
      }
    }

    // Actualitzem límits d'elevació
    if (state.points.isEmpty || newPoint.altitude > newMax)
      newMax = newPoint.altitude;
    if (state.points.isEmpty || newPoint.altitude < newMin)
      newMin = newPoint.altitude;

    // Guardem la distància d'aquest segment acumulada a dins de la UserPosition [INDEX]
    final userPositionWithDistance = newPoint.copyWith(
      distanceAtPoint: calculatedDistanceAtPoint,
    );

    // Reconstruïm el nou bloc de TrackStats compacte [INDEX]
    final updatedStats = state.stats.copyWith(
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
      stoppedDuration: stoppedDuration,
      duration: ref.read(timerProvider),
    );

    // Actualitzem l'estat central de Riverpod d'un sol cop de forma atòmica [INDEX]
    state = state.copyWith(
      points: [...state.points, userPositionWithDistance],
      stats: updatedStats,
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

  // 💾 PERSISTÈNCIA NETEJA (SERIALITZACIÓ DE SUB-MODELS) [INDEX]
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

      final String rawData = jsonEncode({
        'points': pointsMap,
        'recordingState': state.recordingState.index,
        'duration': state.stats.duration.inSeconds,
        'stoppedDuration': state.stats.stoppedDuration.inSeconds,
        'distance': state.stats.distance,
        'ascent': state.stats.ascent,
        'descent': state.stats.descent,
      });

      await prefs.setString('temp_track_data', rawData);
    } catch (e) {
      debugPrint("Error en l'auto-save: $e");
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

      state = Track(
        points: loadedPoints,
        recordingState: RecordingState.values[data['recordingState'] ?? 0],
        stats: TrackStats(
          duration: Duration(seconds: data['duration'] ?? 0),
          stoppedDuration: Duration(seconds: data['stoppedDuration'] ?? 0),
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
