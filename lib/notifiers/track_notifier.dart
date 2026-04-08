import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/notifiers/gps_speed_notifier.dart';
import 'package:gpxly/notifiers/gps_bearing_notifier.dart';

import '../models/track.dart';
import '../services/native_gps_channel.dart';

class TrackNotifier extends Notifier<Track> {
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Track? _initialState;

  @override
  Track build() {
    return _initialState ??= Track(
      coordinates: [],
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
    );
  }

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

    _subscription ??= NativeGpsChannel.locationStream.listen((data) {
      if (state.recordingState != RecordingState.recording) return;

      // 1. Extreure totes les dades del TrackingService.kt
      final double lat = data["lat"] as double;
      final double lon = data["lon"] as double;
      final double accuracy = data["accuracy"] as double;
      final double rawAlt = (data["altitude"] ?? 0.0) as double;
      final double speed = (data["speed"] ?? 0.0) as double;
      final double heading = (data["heading"] ?? 0.0) as double;
      final int satUsed = (data["sat_used"] ?? 0) as int;

      // Precisions i temps real del satèl·lit
      final double vAcc = (data["vAccuracy"] ?? 0.0) as double;
      final double sAcc = (data["sAccuracy"] ?? 0.0) as double;
      final double hAcc = (data["hAccuracy"] ?? 0.0) as double;
      final DateTime gpsTimestamp = DateTime.fromMillisecondsSinceEpoch(
        data["timestamp"] as int,
      );

      // 2. Aplicar correcció d'altitud
      final double correction = localAltitudeCorrection(lat, lon);
      final double correctedAlt = rawAlt - correction;

      // 3. Afegir el punt amb tota la telemetria
      addPointFromPosition(
        Position(
          latitude: lat,
          longitude: lon,
          altitude: correctedAlt,
          timestamp: gpsTimestamp,
          accuracy: accuracy,
          altitudeAccuracy: vAcc,
          heading: heading,
          headingAccuracy: hAcc,
          speed: speed,
          speedAccuracy: sAcc,
          isMocked: false,
        ),
        satUsed,
      );
    });
  }

  void pauseRecording() {
    state = state.copyWith(recordingState: RecordingState.paused);
  }

  void resumeRecording() {
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  Future<void> stopRecording() async {
    await NativeGpsChannel.stop();
    await _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(recordingState: RecordingState.idle);
  }

  void addPointFromPosition(Position pos, [int sat_used = 0]) {
    print("""
>>> GPS DATA RECEIVED:
>>> lat: ${pos.latitude}
>>> lon: ${pos.longitude}
>>> accuracy: ${pos.accuracy}
>>> altitude: ${pos.altitude}
>>> speed: ${pos.speed}
>>> heading: ${pos.heading}
>>> timestamp: ${pos.timestamp}
>>> sat_used: $sat_used
>>> vAccuracy: ${pos.altitudeAccuracy}
>>> sAccuracy: ${pos.speedAccuracy}
>>> hAccuracy: ${pos.headingAccuracy}
    """);

    ref.read(gpsAccuracyProvider.notifier).update(pos.accuracy);
    ref.read(gpsAltitudeProvider.notifier).update(pos.altitude);
    ref.read(gpsSpeedProvider.notifier).update(pos.speed);
    ref.read(gpsBearingProvider.notifier).update(pos.heading);

    double newDistance = state.distance;
    double newAscent = state.ascent;
    double newDescent = state.descent;
    double newMax = state.maxElevation;
    double newMin = state.minElevation;

    if (state.coordinates.isNotEmpty) {
      final lastCoords = state.coordinates.last; // [lon, lat]
      final lastAlt = state.altitudes.last;

      newDistance += Geolocator.distanceBetween(
        lastCoords[1],
        lastCoords[0],
        pos.latitude,
        pos.longitude,
      );

      final double diffAlt = pos.altitude - lastAlt;
      if (diffAlt > 0) {
        newAscent += diffAlt;
      } else if (diffAlt < 0) {
        newDescent += diffAlt.abs();
      }
    }

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
  }

  void addCoordinate(
    double lat,
    double lon,
    double acc,
    double altitude, [
    int sat_used = 0,
  ]) {
    addPointFromPosition(
      Position(
        latitude: lat,
        longitude: lon,
        altitude: altitude,
        timestamp: DateTime.now(),
        accuracy: acc,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      ),
      sat_used,
    );
  }

  void reset() {
    state = Track(
      coordinates: [],
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
    );
  }

  double localAltitudeCorrection(double lat, double lon) {
    if (lat >= 40.0 && lat <= 43.0 && lon >= -1.0 && lon <= 4.0) return 50.0;
    if (lat >= 38.0 && lat < 40.0 && lon >= -1.5 && lon <= 1.5) return 48.0;
    return 0.0;
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);
