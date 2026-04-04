import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track.dart';
import '../services/native_gps_channel.dart';

class TrackNotifier extends Notifier<Track> {
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Track? _initialState;

  @override
  Track build() {
    print(">>> TrackNotifier.build() called");
    return _initialState ??= Track(
      coordinates: [],
      altitudes: [],
      timestamps: [],
      accuracies: [],
      recording: false,
      paused: false,
      duration: Duration.zero,
    );
  }

  Future<void> startRecording(BuildContext context) async {
    if (!state.recording) {
      state = state.copyWith(recording: true, paused: false);
    }

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.recording && !state.paused) {
        state = state.copyWith(
          duration: state.duration + const Duration(seconds: 1),
        );
      }
    });

    _subscription ??= NativeGpsChannel.locationStream.listen((data) {
      if (!state.recording || state.paused) return;

      final lat = data["lat"] as double;
      final lon = data["lon"] as double;
      final accuracy = data["accuracy"] as double;
      final alt = (data["alt"] ?? 0.0) as double;

      addPointFromPosition(
        Position(
          latitude: lat,
          longitude: lon,
          altitude: alt,
          timestamp: DateTime.now(),
          accuracy: accuracy,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          isMocked: false,
        ),
      );
    });
  }

  void pauseRecording() => state = state.copyWith(paused: true);
  void resumeRecording() => state = state.copyWith(paused: false);

  Future<void> stopRecording() async {
    await NativeGpsChannel.stop();
    await _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(recording: false, paused: false);
  }

  void addPointFromPosition(Position pos) {
    print(">>> addPointFromPosition");

    double newDistance = state.distance;
    double newAscent = state.ascent;
    double newDescent = state.descent;
    double newMax = state.maxElevation;
    double newMin = state.minElevation;

    // Si ja hi ha punts, calculem la diferència només amb l'últim punt existent
    if (state.coordinates.isNotEmpty) {
      final lastCoords = state.coordinates.last; // [lon, lat]
      final lastAlt = state.altitudes.last;

      // 1. Distància acumulada
      newDistance += Geolocator.distanceBetween(
        lastCoords[1],
        lastCoords[0],
        pos.latitude,
        pos.longitude,
      );

      // 2. Desnivells (Només si hi ha canvi d'altitud significatiu)
      double diffAlt = pos.altitude - lastAlt;
      if (diffAlt > 0) {
        newAscent += diffAlt;
      } else if (diffAlt < 0) {
        newDescent += diffAlt.abs();
      }
    }

    // 3. Altituds extremes (Inicialitzem si és el primer punt)
    if (state.altitudes.isEmpty) {
      newMax = pos.altitude;
      newMin = pos.altitude;
    } else {
      if (pos.altitude > newMax) newMax = pos.altitude;
      if (pos.altitude < newMin) newMin = pos.altitude;
    }

    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [pos.longitude, pos.latitude],
      ],
      altitudes: [...state.altitudes, pos.altitude],
      timestamps: [...state.timestamps, DateTime.now()],
      accuracies: [...state.accuracies, pos.accuracy],
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
    );
  }

  // Afegeix això dins de la classe TrackNotifier (track_notifier.dart)

  void addCoordinate(double lat, double lon) {
    // Fem servir Position amb altitud 0 per reutilitzar la lògica incremental
    addPointFromPosition(
      Position(
        latitude: lat,
        longitude: lon,
        altitude: 0.0, // Si no tenim l'altitud, posem 0
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      ),
    );
  }

  void reset() {
    state = Track(
      coordinates: [],
      altitudes: [],
      timestamps: [],
      accuracies: [],
      recording: false,
      paused: false,
      duration: Duration.zero,
      distance: 0.0,
      ascent: 0.0,
      descent: 0.0,
      maxElevation: -9999.0,
      minElevation: 9999.0,
    );
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);
