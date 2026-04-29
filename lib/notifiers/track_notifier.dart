import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TrackNotifier extends Notifier<Track> {
  Timer? _timer;
  Track? _initialState;

  bool isFollowing = false;

  @override
  Track build() {
    return _initialState ??= Track(
      coordinates: [],
      distances: [],
      altitudes: [],
      timestamps: [],
      accuracies: [],
      speeds: [],
      headings: [],
      satellites: [],
      vAccuracies: [],
      recordingState: RecordingState.idle,
      duration: Duration.zero,
      distance: 0.0,
      ascent: 0.0,
      descent: 0.0,
      maxElevation: -9999.0,
      minElevation: 9999.0,
      currentPosition: null, // 🔥 afegit
    );
  }

  Future<void> _autoSaveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String rawData = jsonEncode({
        'coordinates': state.coordinates,
        'distances': state.distances,
        'altitudes': state.altitudes,
        'timestamps': state.timestamps.map((t) => t.toIso8601String()).toList(),
        'accuracies': state.accuracies,
        'speeds': state.speeds,
        'headings': state.headings,
        'satellites': state.satellites,
        'vAccuracies': state.vAccuracies,
        'recordingState': state.recordingState.index, // Guardem l'estat
        'duration': state.duration.inSeconds,
        'distance': state.distance,
        'ascent': state.ascent,
        'descent': state.descent,
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

      state = Track(
        coordinates: (data['coordinates'] as List)
            .map((e) => List<double>.from(e))
            .toList(),
        distances: List<double>.from(data['distances'] ?? []),
        altitudes: List<double>.from(data['altitudes']),
        timestamps: (data['timestamps'] as List)
            .map((e) => DateTime.parse(e))
            .toList(),
        accuracies: List<double>.from(data['accuracies']),
        speeds: List<double>.from(data['speeds']),
        headings: List<double>.from(data['headings']),
        satellites: List<int>.from(data['satellites']),
        vAccuracies: List<double>.from(data['vAccuracies']),
        recordingState: RecordingState.values[data['recordingState'] ?? 0],
        duration: Duration(seconds: data['duration'] ?? 0),
        distance: data['distance'] ?? 0.0,
        ascent: data['ascent'] ?? 0.0,
        descent: data['descent'] ?? 0.0,
        maxElevation: (data['altitudes'] as List).cast<double>().reduce(
          (a, b) => a > b ? a : b,
        ),
        minElevation: (data['altitudes'] as List).cast<double>().reduce(
          (a, b) => a < b ? a : b,
        ),
      );
    } catch (e) {
      debugPrint("Error carregant el cache: $e");
    }
  }

  // ───────────────────────────────────────────────
  // 1) PUNT D’ENTRADA ÚNIC DEL GPS
  // ───────────────────────────────────────────────

  void onGpsPoint(Position pos, {int satUsed = 0}) {
    // 1. Actualitzar punt blau
    state = state.copyWith(
      currentPosition: LatLng(pos.latitude, pos.longitude),
    );

    // 2. Si estem gravant → afegir punt
    if (state.recordingState == RecordingState.recording) {
      addPointFromPosition(pos, satUsed);
    }

    // 3. Si estem seguint → enviar al TrackFollowNotifier
    if (isFollowing) {
      final userPos = LatLng(pos.latitude, pos.longitude);
      ref
          .read(trackFollowNotifierProvider.notifier)
          .updateUserPosition(userPos);
    }
  }

  // ───────────────────────────────────────────────
  // 2) CONTROL DE SEGUIMENT
  // ───────────────────────────────────────────────
  void setFollowing(bool value) {
    isFollowing = value;
  }

  // ───────────────────────────────────────────────
  // 3) CONTROL DE GRAVACIÓ (igual que abans)
  // ───────────────────────────────────────────────
  Future<void> startRecording(BuildContext context) async {
    if (state.recordingState != RecordingState.recording) {
      state = state.copyWith(recordingState: RecordingState.recording);
    }

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.recordingState == RecordingState.recording) {
        state = state.copyWith(
          duration: state.duration + const Duration(seconds: 1),
        );
      }
    });
  }

  void pauseRecording() {
    state = state.copyWith(recordingState: RecordingState.paused);
  }

  void resumeRecording() {
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(recordingState: RecordingState.idle);
  }

  // ───────────────────────────────────────────────
  // 4) RECORDER PUR (igual que abans)
  // ───────────────────────────────────────────────
  void addPointFromPosition(Position pos, [int sat_used = 0]) {
    // 1. Actualitzem els micro-providers (com ja feies)
    ref.read(gpsAccuracyProvider.notifier).update(pos.accuracy);
    ref.read(gpsAltitudeProvider.notifier).update(pos.altitude);

    double newDistance = state.distance;
    double newAscent = state.ascent;
    double newDescent = state.descent;
    double newMax = state.maxElevation;
    double newMin = state.minElevation;

    // Creem una còpia de la llista de distàncies actual per afegir-hi el nou valor
    List<double> newDistancesList = [...state.distances];

    if (state.coordinates.isNotEmpty) {
      final lastCoords = state.coordinates.last; // [lon, lat]
      final lastAlt = state.altitudes.last;

      final lastLon = lastCoords[0];
      final lastLat = lastCoords[1];

      // Càlcul correcte
      final double step = Geolocator.distanceBetween(
        lastLat, // ✔️ lat
        lastLon, // ✔️ lon
        pos.latitude, // ✔️ lat
        pos.longitude, // ✔️ lon
      );

      // Filtre anti-bogeries
      if (step.isFinite && step < 200) {
        newDistance += step;
      }

      final double diffAlt = pos.altitude - lastAlt;
      if (diffAlt > 0.5) {
        newAscent += diffAlt;
      } else if (diffAlt < -0.5) {
        newDescent += diffAlt.abs();
      }
    }

    // 2. Afegim la distància total acumulada en aquest punt a la llista
    newDistancesList.add(newDistance);

    // 📈 Actualitzem límits d'elevació
    if (state.altitudes.isEmpty || pos.altitude > newMax) newMax = pos.altitude;
    if (state.altitudes.isEmpty || pos.altitude < newMin) newMin = pos.altitude;

    // 🚀 Actualitzem l'estat amb la nova llista 'distances'
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [pos.longitude, pos.latitude],
      ],
      altitudes: [...state.altitudes, pos.altitude],
      distances: newDistancesList, // <--- LA NOVA LLISTA ACTUALITZADA
      timestamps: [...state.timestamps, pos.timestamp],
      accuracies: [...state.accuracies, pos.accuracy],
      speeds: [...state.speeds, pos.speed],
      headings: [...state.headings, pos.heading],
      satellites: [...state.satellites, sat_used],
      vAccuracies: [...state.vAccuracies, pos.altitudeAccuracy],
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
    );

    // 💾 Auto-save cada 10 punts
    if (state.coordinates.length % 10 == 0) {
      _autoSaveToPrefs();
    }
  }

  // ───────────────────────────────────────────────
  // 5) CACHE, RESET, ALTITUDES (igual que abans)
  // ───────────────────────────────────────────────
  // ... (tot el teu codi actual)
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);

final compassHeadingProvider = Provider<double>((ref) {
  final track = ref.watch(trackProvider);
  if (track.headings.isEmpty) return 0.0;
  return track.headings.last; // heading en graus
});
