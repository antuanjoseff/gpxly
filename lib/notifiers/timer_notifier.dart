import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerNotifier extends Notifier<Duration> {
  Timer? _timer;

  @override
  Duration build() => Duration.zero;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      state = state + const Duration(seconds: 1);
    });
  }

  void pause() => _timer?.cancel();

  void reset() {
    _timer?.cancel();
    state = Duration.zero;
  }

  // Per quan carreguem un track de la memòria cau
  void setInitialValue(Duration duration) => state = duration;
}

final timerProvider = NotifierProvider<TimerNotifier, Duration>(
  TimerNotifier.new,
);
