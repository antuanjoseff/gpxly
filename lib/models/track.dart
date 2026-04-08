enum RecordingState {
  idle, // No gravant
  recording, // Gravació activa
  paused, // Pausa
}

class Track {
  final List<List<double>> coordinates;
  final List<double> altitudes;
  final List<DateTime> timestamps;
  final List<double> accuracies;

  final List<double> speeds;
  final List<double> headings;
  final List<int> satellites;
  final List<double> vAccuracies;

  // Abans: final RecordingState state;
  final RecordingState recordingState;

  final Duration duration;

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
    this.recordingState = RecordingState.idle,
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
    RecordingState? recordingState,
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
      recordingState: recordingState ?? this.recordingState,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      ascent: ascent ?? this.ascent,
      descent: descent ?? this.descent,
      maxElevation: maxElevation ?? this.maxElevation,
      minElevation: minElevation ?? this.minElevation,
    );
  }

  double get currentSpeedKmH => (speeds.isNotEmpty) ? speeds.last * 3.6 : 0.0;
  double get currentHeading => (headings.isNotEmpty) ? headings.last : 0.0;
  int get currentSatellites => (satellites.isNotEmpty) ? satellites.last : 0;
  double get averageSpeed =>
      (duration.inSeconds > 0) ? (distance / duration.inSeconds) * 3.6 : 0.0;

  String get formattedDuration {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  bool get recording => recordingState == RecordingState.recording;
  bool get paused => recordingState == RecordingState.paused;
}
