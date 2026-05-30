import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecorderState {
  final bool isRecording;
  final List<RecorderPoint> points;
  final Duration duration;

  const RecorderState({
    this.isRecording = false,
    this.points = const [],
    this.duration = Duration.zero,
  });

  RecorderState copyWith({
    bool? isRecording,
    List<RecorderPoint>? points,
    Duration? duration,
  }) {
    return RecorderState(
      isRecording: isRecording ?? this.isRecording,
      points: points ?? this.points,
      duration: duration ?? this.duration,
    );
  }
}

class RecorderPoint {
  final double lat;
  final double lon;
  final double? altitude;
  final DateTime timestamp;

  const RecorderPoint({
    required this.lat,
    required this.lon,
    this.altitude,
    required this.timestamp,
  });
}

final recorderProvider = NotifierProvider<Recorder, RecorderState>(
  Recorder.new,
);

class Recorder extends Notifier<RecorderState> {
  @override
  RecorderState build() => const RecorderState();

  // --- Control de gravació ---

  void start() {
    state = state.copyWith(
      isRecording: true,
      points: [],
      duration: Duration.zero,
    );
  }

  void stop() {
    state = state.copyWith(isRecording: false);
  }

  // --- Afegir punts ---

  void addPoint({required double lat, required double lon, double? altitude}) {
    if (!state.isRecording) return;

    final updated = List<RecorderPoint>.from(state.points)
      ..add(
        RecorderPoint(
          lat: lat,
          lon: lon,
          altitude: altitude,
          timestamp: DateTime.now(),
        ),
      );

    state = state.copyWith(points: updated);
  }

  // --- Actualitzar durada ---

  void updateDuration(Duration d) {
    if (!state.isRecording) return;
    state = state.copyWith(duration: d);
  }

  // --- Reset complet ---

  void reset() {
    state = const RecorderState();
  }
}
