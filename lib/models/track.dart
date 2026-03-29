class Track {
  final List<List<double>> coordinates;
  final List<double> altitudes;
  final List<DateTime> timestamps;
  final bool recording;
  final Duration duration;

  Track({
    required this.coordinates,
    required this.altitudes,
    required this.timestamps,
    this.recording = false,
    this.duration = Duration.zero,
  });

  Track copyWith({
    List<List<double>>? coordinates,
    List<double>? altitudes,
    List<DateTime>? timestamps,
    bool? recording,
    Duration? duration,
  }) {
    return Track(
      coordinates: coordinates ?? this.coordinates,
      altitudes: altitudes ?? this.altitudes,
      timestamps: timestamps ?? this.timestamps,
      recording: recording ?? this.recording,
      duration: duration ?? this.duration,
    );
  }

  String get formattedDuration {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}
