class Track {
  final List<List<double>> coordinates;
  final List<double> altitudes;
  final List<DateTime> timestamps;
  final List<double> accuracies;

  // 🔹 Noves llistes de telemetria GPS
  final List<double> speeds; // en m/s
  final List<double> headings; // en graus
  final List<int> satellites; // sat_used
  final List<double> vAccuracies; // vertical accuracy

  final bool recording;
  final bool paused;
  final Duration duration;

  // Camps acumulats
  final double distance;
  final double ascent;
  final double descent;
  final double maxElevation;
  final double minElevation;

  Track({
    required this.coordinates,
    required this.altitudes,
    required this.timestamps,
    required this.accuracies,
    this.speeds = const [],
    this.headings = const [],
    this.satellites = const [],
    this.vAccuracies = const [],
    this.recording = false,
    this.paused = false,
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.ascent = 0.0,
    this.descent = 0.0,
    this.maxElevation = -9999.0,
    this.minElevation = 9999.0,
  });

  Track copyWith({
    List<List<double>>? coordinates,
    List<double>? altitudes,
    List<DateTime>? timestamps,
    List<double>? accuracies,
    List<double>? speeds,
    List<double>? headings,
    List<int>? satellites,
    List<double>? vAccuracies,
    bool? recording,
    bool? paused,
    Duration? duration,
    double? distance,
    double? ascent,
    double? descent,
    double? maxElevation,
    double? minElevation,
  }) {
    return Track(
      coordinates: coordinates ?? this.coordinates,
      altitudes: altitudes ?? this.altitudes,
      timestamps: timestamps ?? this.timestamps,
      accuracies: accuracies ?? this.accuracies,
      speeds: speeds ?? this.speeds,
      headings: headings ?? this.headings,
      satellites: satellites ?? this.satellites,
      vAccuracies: vAccuracies ?? this.vAccuracies,
      recording: recording ?? this.recording,
      paused: paused ?? this.paused,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      ascent: ascent ?? this.ascent,
      descent: descent ?? this.descent,
      maxElevation: maxElevation ?? this.maxElevation,
      minElevation: minElevation ?? this.minElevation,
    );
  }

  // --- Getters auxiliars ---

  // Velocitat actual en km/h
  double get currentSpeedKmH => (speeds.isNotEmpty) ? speeds.last * 3.6 : 0.0;

  // Rumb actual
  double get currentHeading => (headings.isNotEmpty) ? headings.last : 0.0;

  // Satèl·lits actuals
  int get currentSatellites => (satellites.isNotEmpty) ? satellites.last : 0;

  // Velocitat mitjana (km/h)
  double get averageSpeed =>
      (duration.inSeconds > 0) ? (distance / duration.inSeconds) * 3.6 : 0.0;

  String get formattedDuration {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}
