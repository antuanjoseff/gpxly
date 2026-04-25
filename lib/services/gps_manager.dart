import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:geolocator/geolocator.dart';

class GpsManagerState {
  final LatLng? position;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final int? satellites;

  const GpsManagerState({
    this.position,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.satellites,
  });

  GpsManagerState copyWith({
    LatLng? position,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    int? satellites,
  }) {
    return GpsManagerState(
      position: position ?? this.position,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      satellites: satellites ?? this.satellites,
    );
  }
}

class GpsManager extends Notifier<GpsManagerState> {
  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  bool recording = false;
  bool following = false;

  @override
  GpsManagerState build() {
    ref.onDispose(() => _gpsSub?.cancel());
    return const GpsManagerState();
  }

  // ------------------------------------------------------------
  // ACTIVAR GPS
  // ------------------------------------------------------------
  Future<void> startGps({
    required bool useTime,
    required int seconds,
    required double meters,
    required double accuracy,
  }) async {
    await NativeGpsChannel.start(
      useTime: useTime,
      seconds: seconds,
      meters: meters,
      accuracy: accuracy,
    );

    _gpsSub ??= NativeGpsChannel.positionStream().listen(_onGpsData);
  }

  // ------------------------------------------------------------
  // DESACTIVAR GPS
  // ------------------------------------------------------------
  Future<void> stopGps() async {
    await NativeGpsChannel.stop();
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  // ------------------------------------------------------------
  // REP DADES DEL GPS (ÚNIC LLOC)
  // ------------------------------------------------------------
  // ------------------------------------------------------------
  // REP DADES DEL GPS (ÚNIC LLOC)
  // ------------------------------------------------------------
  void _onGpsData(Map<String, dynamic> data) {
    final lat = data["lat"] as double;
    final lon = data["lon"] as double;
    final pos = LatLng(lat, lon);

    // PAS 1: Actualitzem el Notifier de Gravació (si toca)
    // Ho fem primer perquè quan la UI pregunti per les coordenades
    // per fer l'animació, ja tingui el nou punt a la llista.
    if (recording) {
      ref
          .read(trackProvider.notifier)
          .addPointFromPosition(
            Position(
              latitude: lat,
              longitude: lon,
              altitude: (data["altitude"] ?? 0.0) as double,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                data["timestamp"] as int,
              ),
              accuracy: (data["accuracy"] ?? 0.0) as double,
              altitudeAccuracy: (data["vAccuracy"] ?? 0.0) as double,
              heading: (data["heading"] ?? 0.0) as double,
              headingAccuracy: (data["hAccuracy"] ?? 0.0) as double,
              speed: (data["speed"] ?? 0.0) as double,
              speedAccuracy: (data["sAccuracy"] ?? 0.0) as double,
              isMocked: false,
            ),
            (data["sat_used"] ?? 0) as int,
          );
    }

    // PAS 2: Actualitzem el Notifier de Seguiment (si toca)
    // Això calcula si estem fora de ruta, distàncies, etc.
    if (following) {
      ref.read(trackFollowNotifierProvider.notifier).updateUserPosition(pos);
    }

    // PAS 3: Actualitzem l'estat propi del GpsManager.
    // Aquest és el pas final perquè és el que dispara el 'ref.listen'
    // a la MapScreen que inicia l'animació visual del punt blau i la línia.
    state = state.copyWith(
      position: pos,
      accuracy: data["accuracy"] as double?,
      altitude: data["altitude"] as double?,
      speed: data["speed"] as double?,
      heading: data["heading"] as double?,
      satellites: data["sat_used"] as int?,
    );
  }

  // ------------------------------------------------------------
  // FLAGS
  // ------------------------------------------------------------
  void setRecording(bool value) => recording = value;
  void setFollowing(bool value) => following = value;
}

final gpsManagerProvider = NotifierProvider<GpsManager, GpsManagerState>(
  GpsManager.new,
);
