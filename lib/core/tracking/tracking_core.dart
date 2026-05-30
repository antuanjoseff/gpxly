import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackingState {
  final bool isRecording;
  final bool isFollowing;
  final double totalDistance;
  final double segmentDistance;
  final int currentSegmentIndex;
  final double deviation;
  final double remainingDistance;
  final double? currentAltitude;

  const TrackingState({
    this.isRecording = false,
    this.isFollowing = false,
    this.totalDistance = 0.0,
    this.segmentDistance = 0.0,
    this.currentSegmentIndex = 0,
    this.deviation = 0.0,
    this.remainingDistance = 0.0,
    this.currentAltitude = 0.0,
  });

  TrackingState copyWith({
    bool? isRecording,
    bool? isFollowing,
    double? totalDistance,
    double? segmentDistance,
    int? currentSegmentIndex,
    double? deviation,
    double? remainingDistance,
    double? currentAltitude,
  }) {
    return TrackingState(
      isRecording: isRecording ?? this.isRecording,
      isFollowing: isFollowing ?? this.isFollowing,
      totalDistance: totalDistance ?? this.totalDistance,
      segmentDistance: segmentDistance ?? this.segmentDistance,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      deviation: deviation ?? this.deviation,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      currentAltitude: currentAltitude ?? this.currentAltitude,
    );
  }
}

final trackingCoreProvider = NotifierProvider<TrackingCore, TrackingState>(
  TrackingCore.new,
);

class TrackingCore extends Notifier<TrackingState> {
  @override
  TrackingState build() => const TrackingState();

  // --- Control de modes ---

  void startRecording() {
    state = state.copyWith(isRecording: true);
  }

  void stopRecording() {
    state = state.copyWith(isRecording: false);
  }

  void startFollowing() {
    state = state.copyWith(isFollowing: true);
  }

  void stopFollowing() {
    state = state.copyWith(isFollowing: false);
  }

  // --- Distàncies ---

  void updateTotalDistance(double value) {
    state = state.copyWith(totalDistance: value);
  }

  void updateSegmentDistance(double value) {
    state = state.copyWith(segmentDistance: value);
  }

  // --- Seguiment de segments ---

  void updateSegmentIndex(int index) {
    state = state.copyWith(currentSegmentIndex: index);
  }

  // --- Offtrack / desviació ---

  void updateDeviation(double value) {
    state = state.copyWith(deviation: value);
  }

  // --- Distància restant ---

  void updateRemainingDistance(double value) {
    state = state.copyWith(remainingDistance: value);
  }

  void updateAltitude(double value) {
    state = state.copyWith(currentAltitude: value);
  }

  // --- Reset complet ---

  void reset() {
    state = const TrackingState();
  }
}
