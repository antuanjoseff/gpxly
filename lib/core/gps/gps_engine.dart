import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estat mínim del motor GPS.
/// Ara inclou altitude i zoom correctament.
class GpsState {
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? bearing;
  final double? accuracy;
  final double? altitude;
  final double? zoom;
  final int? satellites;

  const GpsState({
    this.latitude,
    this.longitude,
    this.speed,
    this.bearing,
    this.accuracy,
    this.altitude,
    this.zoom,
    this.satellites,
  });

  GpsState copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    double? accuracy,
    double? altitude,
    double? zoom,
    int? satellites,
  }) {
    return GpsState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      zoom: zoom ?? this.zoom,
      satellites: satellites ?? this.satellites,
    );
  }
}

/// Provider del motor GPS.
final gpsEngineProvider = NotifierProvider<GpsEngine, GpsState>(GpsEngine.new);

class GpsEngine extends Notifier<GpsState> {
  @override
  GpsState build() => const GpsState();

  // ---------------------------------------------------------------------------
  // Actualitzadors individuals
  // ---------------------------------------------------------------------------

  void updateSpeed(double speed) {
    state = state.copyWith(speed: speed);
  }

  void updatePosition({
    required double lat,
    required double lon,
    double? accuracy,
  }) {
    state = state.copyWith(
      latitude: lat,
      longitude: lon,
      accuracy: accuracy ?? state.accuracy,
    );
  }

  void updateBearing(double bearing) {
    state = state.copyWith(bearing: bearing);
  }

  void updateAccuracy(double accuracy) {
    state = state.copyWith(accuracy: accuracy);
  }

  void updateAltitude(double altitude) {
    state = state.copyWith(altitude: altitude);
  }

  void updateSatellites(int count) {
    state = state.copyWith(satellites: count);
  }

  void updateZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  // ---------------------------------------------------------------------------
  // Control del motor (placeholder)
  // ---------------------------------------------------------------------------

  void start() {
    // Aquí connectarem NativeGpsChannel.positionStream()
  }

  void stop() {
    // Aquí desconnectarem el stream
  }
}
