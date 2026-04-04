import 'package:geolocator/geolocator.dart';

class Track {
  final List<List<double>> coordinates;
  final List<double> altitudes;
  final List<DateTime> timestamps;
  final List<double> accuracies;
  final bool recording;
  final bool paused;
  final Duration duration;

  // Camps per a dades acumulades (Pre-calculades)
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
    this.recording = false,
    this.paused = false,
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.ascent = 0.0,
    this.descent = 0.0,
    this.maxElevation = -9999.0, // Valor inicial baix
    this.minElevation = 9999.0, // Valor inicial alt
  });

  // Actualitza el copyWith per incloure aquests nous camps
  Track copyWith({
    List<List<double>>? coordinates,
    List<double>? altitudes,
    List<DateTime>? timestamps,
    List<double>? accuracies,
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
