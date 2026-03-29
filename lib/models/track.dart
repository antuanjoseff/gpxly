class Track {
  final List<List<double>> coordinates;
  final List<double> altitudes;
  final List<DateTime> timestamps;

  Track({
    required this.coordinates,
    required this.altitudes,
    required this.timestamps,
  });

  Track copyWith({
    List<List<double>>? coordinates,
    List<double>? altitudes,
    List<DateTime>? timestamps,
  }) {
    return Track(
      coordinates: coordinates ?? this.coordinates,
      altitudes: altitudes ?? this.altitudes,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
