// lib/models/user_position.dart
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

  // 🛰️ APARTAT NOU: Afegits per al diagnòstic de la targeta de satèl·lits de STrack Rec
  final int satellitesUsed;
  final int satellitesInView;

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
    this.satellitesUsed = 0, // 👈 Nou camp afegit amb valor per defecte
    this.satellitesInView = 0, // 👈 Nou camp afegit amb valor per defecte
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
    int? satellitesUsed, // 👈 Afegit al copyWith
    int? satellitesInView, // 👈 Afegit al copyWith
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
      satellitesUsed: satellitesUsed ?? this.satellitesUsed, // 👈 Mapejat
      satellitesInView: satellitesInView ?? this.satellitesInView, // 👈 Mapejat
    );
  }
}
