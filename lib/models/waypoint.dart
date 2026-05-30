import 'package:maplibre_gl/maplibre_gl.dart';

class Waypoint {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int trackIndex;
  final double? distanceAtPoint;
  final double? ele;
  final DateTime? time;

  const Waypoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.trackIndex,
    this.distanceAtPoint,
    this.ele,
    this.time,
  });

  Waypoint copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
    int? trackIndex,
    double? distanceAtPoint,
    double? ele,
    DateTime? time,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      trackIndex: trackIndex ?? this.trackIndex,
      distanceAtPoint: distanceAtPoint ?? this.distanceAtPoint,
      ele: ele ?? this.ele,
      time: time ?? this.time,
    );
  }

  // Ajuda ràpida per a les capes visuals del mapa de MapLibre
  LatLng toLatLng() => LatLng(lat, lon);
}
