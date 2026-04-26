class Waypoint {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int trackIndex;

  const Waypoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.trackIndex,
  });

  Waypoint copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
    int? trackIndex,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      trackIndex: trackIndex ?? this.trackIndex,
    );
  }
}
