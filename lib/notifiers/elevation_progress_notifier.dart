import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definim un estat que pugui contenir el progrés i un possible error
class ElevationProgressState {
  final double progress;
  final String? error;

  ElevationProgressState({required this.progress, this.error});
}

class ElevationProgressNotifier extends Notifier<ElevationProgressState> {
  @override
  ElevationProgressState build() {
    // Estat inicial: 0% i sense errors
    return ElevationProgressState(progress: 0.0);
  }

  void update(double value) {
    state = ElevationProgressState(progress: value);
  }

  void setError(String message) {
    state = ElevationProgressState(progress: state.progress, error: message);
  }

  void reset() {
    state = ElevationProgressState(progress: 0.0);
  }
}

// El provider amb la sintaxi NotifierProvider
final elevationProgressProvider =
    NotifierProvider<ElevationProgressNotifier, ElevationProgressState>(
      ElevationProgressNotifier.new,
    );
