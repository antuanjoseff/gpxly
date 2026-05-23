import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/elevation_range_notifier.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/notifiers/gps_bearing_notifier.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_follow_notifier.dart';
import 'package:senda/services/cog_service.dart';
import 'package:senda/services/native_gps_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

class TrackNotifier extends Notifier<Track> {
  Track? _initialState;
  StreamSubscription? _gpsSub;
  bool gpsActive = false;
  final _positionStreamController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get positionStream => _positionStreamController.stream;

  final _cogService = CogService();

  @override
  Track build() {
    ref.onDispose(() {
      _gpsSub?.cancel();
      _positionStreamController.close();
      _cogService.dispose();
    });

    return _initialState ??= Track(
      coordinates: [],
      distances: [],
      altitudes: [],
      isHgtFixed: [],
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
      currentPosition: null,
    );
  }

  void startGpsListener() {
    _gpsSub?.cancel();

    _gpsSub = NativeGpsChannel.positionStream().listen((data) {
      onNativeGpsPoint(data);
    });
  }

  Future<void> applyGpsMode() async {
    // Ara la configuració del GPS la fa gpsSettingsProvider
    await ref.read(gpsSettingsProvider.notifier).apply();
  }

  Future<void> ensureGpsStarted() async {
    if (gpsActive) return;

    await ref.read(gpsSettingsProvider.notifier).initialized;

    // 🔥 Deixa que gpsSettingsProvider decideixi com iniciar el GPS
    await ref.read(gpsSettingsProvider.notifier).apply();

    startGpsListener();
    gpsActive = true;
  }

  void onNativeGpsPoint(Map<String, dynamic> data) async {
    final lat = data["lat"] as double;
    final lon = data["lon"] as double;
    final accuracy = data["accuracy"] as double;
    final altitude = data["altitude"] as double;
    final speed = data["speed"] as double;
    final heading = data["heading"] as double;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(data["timestamp"]);
    final vAccuracy = data["vAccuracy"] as double;
    final satellites = data["satellites"] as int? ?? 0;

    // --- MEJORA DE FLUIDEZ ---
    // Actualizamos la posición en el mapa ANTES del await.
    // Así la flecha se mueve al instante sin esperar a la descarga.
    ref.read(gpsBearingProvider.notifier).update(heading);
    ref.read(gpsAccuracyProvider.notifier).update(accuracy);

    state = state.copyWith(
      currentPosition: LatLng(lat, lon),
      currentHeading: heading,
    );
    _positionStreamController.add(LatLng(lat, lon));

    final gps = ref.read(gpsSettingsProvider);
    if (gps.isFollowing) {
      ref
          .read(trackFollowNotifierProvider.notifier)
          .updateUserPosition(LatLng(lat, lon), userHeading: heading);
    }

    // --- CORRECCIÓN ASÍNCRONA ---
    // Desestructuramos la tupla (altura, booleano) correctamente
    final (correctedAlt, isFixed) = await _cogService.getCorrectedElevation(
      lat,
      lon,
      altitude,
    );

    // Ahora sí pasamos el double (correctedAlt) al provider
    ref
        .read(gpsAltitudeProvider.notifier)
        .update(correctedAlt, horizontalAccuracy: accuracy);

    if (state.recordingState == RecordingState.recording) {
      addPointFromRaw(
        lat: lat,
        lon: lon,
        accuracy: accuracy,
        altitude: correctedAlt, // Pasamos el double corregido
        isHgtFixed: isFixed, // Pasamos el booleano
        speed: speed,
        heading: heading,
        timestamp: timestamp,
        vAccuracy: vAccuracy,
        satellites: satellites,
      );
    }
  }

  void addPointFromRaw({
    required double lat,
    required double lon,
    required double accuracy,
    required double altitude,
    required bool isHgtFixed,
    required double speed,
    required double heading,
    required DateTime timestamp,
    required double vAccuracy,
    required int satellites,
  }) {
    // 1. Actualitzem els micro-providers

    double newDistance = state.distance;
    double newAscent = state.ascent;
    double newDescent = state.descent;
    double newMax = state.maxElevation;
    double newMin = state.minElevation;

    // Copiem la llista de distàncies
    List<double> newDistancesList = [...state.distances];

    if (state.coordinates.isNotEmpty) {
      final lastCoords = state.coordinates.last; // [lon, lat]
      final lastAlt = state.altitudes.last;

      final lastLon = lastCoords[0];
      final lastLat = lastCoords[1];

      // Mateix càlcul que addPointFromPosition, però amb valors RAW
      final double step = Geolocator.distanceBetween(
        lastLat, // ✔️ lat anterior
        lastLon, // ✔️ lon anterior
        lat, // ✔️ lat nova
        lon, // ✔️ lon nova
      );

      // Filtre anti-bogeries
      if (step.isFinite && step < 200) {
        newDistance += step;
      }

      final double diffAlt = altitude - lastAlt;
      if (diffAlt > 0.5) {
        newAscent += diffAlt;
      } else if (diffAlt < -0.5) {
        newDescent += diffAlt.abs();
      }
    }

    // Afegim la distància acumulada
    newDistancesList.add(newDistance);

    // Actualitzem límits d'elevació
    if (state.altitudes.isEmpty || altitude > newMax) newMax = altitude;
    if (state.altitudes.isEmpty || altitude < newMin) newMin = altitude;

    // Actualitzem estat
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [lon, lat],
      ],
      altitudes: [...state.altitudes, altitude],
      isHgtFixed: [...state.isHgtFixed, isHgtFixed],
      distances: newDistancesList,
      timestamps: [...state.timestamps, timestamp],
      accuracies: [...state.accuracies, accuracy],
      speeds: [...state.speeds, speed],
      headings: [...state.headings, heading],
      currentHeading: heading,
      satellites: [...state.satellites, satellites],
      vAccuracies: [...state.vAccuracies, vAccuracy],
      distance: newDistance,
      ascent: newAscent,
      descent: newDescent,
      maxElevation: newMax,
      minElevation: newMin,
    );
    // Actualitzar el rang d’elevacions per al gràfic si estem gravant
    if (state.recordingState == RecordingState.recording) {
      ref.read(elevationRangeProvider.notifier).updateWithNewAltitude(altitude);
    }

    // Auto-save cada 10 punts
    if (state.coordinates.length % 10 == 0) {
      _autoSaveToPrefs();
    }
  }

  Future<void> _autoSaveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String rawData = jsonEncode({
        'coordinates': state.coordinates,
        'distances': state.distances,
        'altitudes': state.altitudes,
        'isHgtFixed': state.isHgtFixed,
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

      // Llegim les altituds primer per saber la longitud
      final List<double> alts = List<double>.from(data['altitudes'] ?? []);

      state = Track(
        coordinates: (data['coordinates'] as List)
            .map((e) => List<double>.from(e))
            .toList(),
        distances: List<double>.from(data['distances'] ?? []),
        altitudes: alts,
        // 🔥 Novetat: si no hi és al JSON, creem una llista de 'false'
        isHgtFixed: data['isHgtFixed'] != null
            ? List<bool>.from(data['isHgtFixed'])
            : List.filled(alts.length, false),
        timestamps: (data['timestamps'] as List)
            .map((e) => DateTime.parse(e))
            .toList(),
        accuracies: List<double>.from(data['accuracies'] ?? []),
        speeds: List<double>.from(data['speeds'] ?? []),
        headings: List<double>.from(data['headings'] ?? []),
        satellites: List<int>.from(data['satellites'] ?? []),
        vAccuracies: List<double>.from(data['vAccuracies'] ?? []),
        recordingState: RecordingState.values[data['recordingState'] ?? 0],
        duration: Duration(seconds: data['duration'] ?? 0),
        distance: data['distance'] ?? 0.0,
        ascent: data['ascent'] ?? 0.0,
        descent: data['descent'] ?? 0.0,
        maxElevation: alts.isEmpty
            ? -9999.0
            : alts.reduce((a, b) => a > b ? a : b),
        minElevation: alts.isEmpty
            ? 9999.0
            : alts.reduce((a, b) => a < b ? a : b),
      );
    } catch (e) {
      debugPrint("Error carregant el cache: $e");
    }
  }

  // ───────────────────────────────────────────────
  // 3) CONTROL DE GRAVACIÓ (igual que abans)
  // ───────────────────────────────────────────────
  // 1. startRecording: Ja no inicia el cronòmetre aquí, ho fa el RecordingHandler
  Future<void> startRecording(BuildContext context) async {
    ref.read(timerProvider.notifier).reset();
    ref.read(timerProvider.notifier).start();
    state = state.copyWith(
      recordingState: RecordingState.recording,
      duration: Duration.zero,
      // coordinates: [], etc. (la teva lògica de reset)
    );
    ref.read(elevationRangeProvider.notifier).reset();
  }

  void pauseRecording() {
    ref.read(timerProvider.notifier).pause();
    final elapsed = ref.read(timerProvider);
    state = state.copyWith(
      recordingState: RecordingState.paused,
      duration: elapsed,
    );
  }

  // 2. continueRecording: Només canvia l'estat, el timer ja l'hem engegat fora
  void continueRecording() {
    ref.read(timerProvider.notifier).resume();
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  void resumeRecording() {
    ref.read(timerProvider.notifier).resume();
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  // 3. stopRecording: Aquest és el canvi més important
  Future<void> stopRecording(Duration finalDuration) async {
    final total = ref.read(timerProvider); // ja és base + elapsed
    ref.read(timerProvider.notifier).pause();

    state = state.copyWith(
      recordingState: RecordingState.idle,
      duration: total,
    );

    await _autoSaveToPrefs();
  }

  // ───────────────────────────────────────────────
  // 4) CACHE, RESET, ALTITUDES (igual que abans)
  // ───────────────────────────────────────────────
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_track_data');
  }

  void reset() {
    state = Track(
      coordinates: [],
      distances: [],
      altitudes: [],
      isHgtFixed: [], // 🔥 Inicialitzat buit
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
    clearCache();
  }

  void stopGpsIfNotNeeded() {
    final alarms = ref.read(alarmSettingsProvider);
    final gps = ref.read(gpsSettingsProvider);

    final anyAlarmEnabled =
        alarms.distanceEnabled || alarms.altitudeEnabled || alarms.timeEnabled;

    final isRecording = state.recordingState == RecordingState.recording;

    if (!isRecording && !gps.isFollowing && !anyAlarmEnabled) {
      NativeGpsChannel.stop();
      _gpsSub?.cancel();
      gpsActive = false;
      return;
    }

    // Deixa que gpsSettingsProvider decideixi la configuració
    ref.read(gpsSettingsProvider.notifier).apply();
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);
