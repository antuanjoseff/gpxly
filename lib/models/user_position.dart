import 'package:maplibre_gl/maplibre_gl.dart';

class UserPosition {
  final LatLng position;
  final double altitude;
  final bool isHgtFixed;
  final DateTime timestamp;
  final double accuracy;
  final double vAccuracy;
  final double
  distanceAtPoint; // Distància acumulada des de l'inici fins a aquest punt
  final double speed; // En m/s
  final double heading; // En graus (0-360)
  final int satellites;

  UserPosition({
    required this.position,
    required this.altitude,
    required this.isHgtFixed,
    required this.timestamp,
    required this.accuracy,
    this.vAccuracy = 0.0,
    this.distanceAtPoint = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    this.satellites = 0,
  });

  UserPosition copyWith({
    LatLng? position,
    double? altitude,
    bool? isHgtFixed,
    DateTime? timestamp,
    double? accuracy,
    double? vAccuracy,
    double? distanceAtPoint,
    double? speed,
    double? heading,
    int? satellites,
  }) {
    return UserPosition(
      position: position ?? this.position,
      altitude: altitude ?? this.altitude,
      isHgtFixed: isHgtFixed ?? this.isHgtFixed,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      vAccuracy: vAccuracy ?? this.vAccuracy,
      distanceAtPoint: distanceAtPoint ?? this.distanceAtPoint,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      satellites: satellites ?? this.satellites,
    );
  }
}
