import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track.dart';
import '../services/native_gps_channel.dart';

class TrackNotifier extends Notifier<Track> {
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  // 🔥 Estat inicial persistent (NO es reinicia quan el provider es reconstrueix)
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
    // Si venim de Resume → no reiniciem duració
    if (!state.recording) {
      state = state.copyWith(recording: true, paused: false);
    }

    // Timer
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.recording && !state.paused) {
        state = state.copyWith(
          duration: state.duration + const Duration(seconds: 1),
        );
      }
    });

    // Subscriure al GPS només si no existia
    _subscription ??= NativeGpsChannel.locationStream.listen((data) {
      if (!state.recording || state.paused) return;

      final lat = data["lat"] as double;
      final lon = data["lon"] as double;
      final accuracy = data["accuracy"] as double;

      addPointFromPosition(
        Position(
          latitude: lat,
          longitude: lon,
          altitude: 0,
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

  void pauseRecording() {
    state = state.copyWith(paused: true);
  }

  void resumeRecording() {
    state = state.copyWith(paused: false);
  }

  Future<void> stopRecording() async {
    // 1. Aturar servei natiu
    await NativeGpsChannel.stop();

    // 2. Cancel·lar escolta d’events
    await _subscription?.cancel();
    _subscription = null;

    // 3. Aturar timer
    _timer?.cancel();
    _timer = null;

    // 4. Actualitzar estat
    state = state.copyWith(recording: false, paused: false);
  }

  void addCoordinate(double lat, double lon) {
    print(">>> addCoordinate");
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [lon, lat], // GeoJSON = [lon, lat]
      ],
    );
  }

  void addPointFromPosition(Position pos) {
    print(">>> addPointFromPosition");
    final now = DateTime.now();
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [pos.longitude, pos.latitude],
      ],
      altitudes: [...state.altitudes, pos.altitude],
      timestamps: [...state.timestamps, now],
      accuracies: [...state.accuracies, pos.accuracy],
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
    );
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);
