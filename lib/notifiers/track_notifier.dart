import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/elevation_progress_notifier.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/services/elevations_api_conf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../services/native_gps_channel.dart';
import 'package:http/http.dart' as http;

class TrackNotifier extends Notifier<Track> {
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Track? _initialState;

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

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_track_data');
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _subscription?.cancel();
    _subscription = null;

    state = Track(
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
    );
    clearCache();
  }

  double localAltitudeCorrection(double lat, double lon) {
    if (lat >= 40.0 && lat <= 43.0 && lon >= -1.0 && lon <= 4.0) return 50.0;
    if (lat >= 38.0 && lat < 40.0 && lon >= -1.5 && lon <= 1.5) return 48.0;
    return 0.0;
  }

  // Future<void> correctTrackAltitudes() async {
  //   final progressNotifier = ref.read(elevationProgressProvider.notifier);

  //   print("debug: Iniciant correcció per a ${state.coordinates.length} punts");

  //   if (state.coordinates.isEmpty) {
  //     progressNotifier.setError("No hi ha dades per corregir");
  //     return;
  //   }

  //   final List<List<double>> allCoords = state.coordinates;
  //   final List<double> correctedAltitudes = [];

  //   // 1. Resetegem l'estat del progrés al començar
  //   progressNotifier.reset();

  //   try {
  //     for (int i = 0; i < allCoords.length; i += ApiConfig.elevationBatchSize) {
  //       final end = (i + ApiConfig.elevationBatchSize < allCoords.length)
  //           ? i + ApiConfig.elevationBatchSize
  //           : allCoords.length;

  //       final segment = allCoords.sublist(i, end);

  //       // Open-Elevation format: c[1] és lat, c[0] és lon (segons el teu model [lon, lat])
  //       final locations = segment
  //           .map((c) => {"latitude": c[1], "longitude": c[0]})
  //           .toList();

  //       final response = await http
  //           .post(
  //             Uri.parse(ApiConfig.elevationApiUrl),
  //             headers: {"Content-Type": "application/json"},
  //             body: jsonEncode({"locations": locations}),
  //           )
  //           .timeout(const Duration(seconds: 15));

  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         final results = data['results'] as List;

  //         correctedAltitudes.addAll(
  //           results.map((r) => (r['elevation'] as num).toDouble()),
  //         );

  //         // 2. Actualitzem el progrés (0.0 a 1.0)
  //         final progress = correctedAltitudes.length / allCoords.length;
  //         progressNotifier.update(progress);
  //       } else {
  //         // Si l'API respon però amb error (ex: 500, 404)
  //         progressNotifier.setError(
  //           "Error del servidor (Codi: ${response.statusCode})",
  //         );
  //         throw Exception("Error API: ${response.statusCode}");
  //       }

  //       // Petit respir per no saturar l'API i permetre que la UI respiri
  //       await Future.delayed(const Duration(milliseconds: 100));
  //     }

  //     // 3. Verificació final i càlcul d'estadístiques
  //     if (correctedAltitudes.length == allCoords.length) {
  //       double newAscent = 0;
  //       double newDescent = 0;
  //       for (int i = 0; i < correctedAltitudes.length - 1; i++) {
  //         double diff = correctedAltitudes[i + 1] - correctedAltitudes[i];
  //         if (diff > 0.5)
  //           newAscent += diff;
  //         else if (diff < -0.5)
  //           newDescent += diff.abs();
  //       }

  //       // 4. Actualitzem l'estat del Track amb les dades netes
  //       state = state.copyWith(
  //         altitudes: correctedAltitudes,
  //         ascent: newAscent,
  //         descent: newDescent,
  //         maxElevation: correctedAltitudes.reduce((a, b) => a > b ? a : b),
  //         minElevation: correctedAltitudes.reduce((a, b) => a < b ? a : b),
  //       );

  //       // 🔥 Forcem el 100% visual abans de tancar
  //       progressNotifier.update(1.0);

  //       await _autoSaveToPrefs();
  //     }
  //   } catch (e) {
  //     debugPrint("debug: Error corregint altituds: $e");

  //     // 5. Informem de l'error al Notifier perquè el diàleg el mostri
  //     String errorMsg = "Error de connexió. Revisa internet.";
  //     if (e.toString().contains("TimeoutException")) {
  //       errorMsg = "El servidor triga massa a respondre.";
  //     }
  //     progressNotifier.setError(errorMsg);

  //     rethrow; // Re-llancem l'error per al 'catch' del botó a la UI
  //   }
  // }

  Future<void> correctTrackAltitudes() async {
    final progressNotifier = ref.read(elevationProgressProvider.notifier);
    if (state.coordinates.isEmpty) return;

    final allCoords = state.coordinates;
    final List<double> correctedAltitudes = [];
    progressNotifier.reset();

    try {
      for (int i = 0; i < allCoords.length; i += ApiConfig.elevationBatchSize) {
        final end = (i + ApiConfig.elevationBatchSize < allCoords.length)
            ? i + ApiConfig.elevationBatchSize
            : allCoords.length;

        final segment = allCoords.sublist(i, end);

        // 1. Preparem les cadenes de text (c[1] lat, c[0] lon)
        final String lats = segment.map((c) => c[1].toString()).join(",");
        final String lons = segment.map((c) => c[0].toString()).join(",");

        // 2. CONSTRUCCIÓ SEGURA (Uri.https gestiona el protocol i les barres)
        final url = Uri.https(
          ApiConfig.elevationApiHost,
          ApiConfig.elevationApiPath,
          {'latitude': lats, 'longitude': lons},
        );

        try {
          final response = await http
              .get(url)
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);

            if (data.containsKey('elevation')) {
              final List<dynamic> elevations = data['elevation'];
              correctedAltitudes.addAll(
                elevations.map((e) => (e as num).toDouble()),
              );
            }

            final progress = correctedAltitudes.length / allCoords.length;
            progressNotifier.update(progress);
          } else {
            throw Exception("Status ${response.statusCode}");
          }
        } catch (e) {
          rethrow;
        }
      }

      // --- FINALITZACIÓ ---
      if (correctedAltitudes.length == allCoords.length) {
        double newAscent = 0;
        double newDescent = 0;

        for (int i = 0; i < correctedAltitudes.length - 1; i++) {
          double diff = correctedAltitudes[i + 1] - correctedAltitudes[i];
          if (diff > 0.5) {
            newAscent += diff;
          } else if (diff < -0.5) {
            newDescent += diff.abs();
          }
        }

        state = state.copyWith(
          altitudes: correctedAltitudes,
          ascent: newAscent,
          descent: newDescent,
          maxElevation: correctedAltitudes.reduce((a, b) => a > b ? a : b),
          minElevation: correctedAltitudes.reduce((a, b) => a < b ? a : b),
        );

        progressNotifier.update(1.0);
        await _autoSaveToPrefs();
      }
    } catch (e, stackTrace) {
      progressNotifier.setError("Error: $e");
      rethrow;
    }
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);
