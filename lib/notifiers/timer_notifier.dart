import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerNotifier extends Notifier<Duration> {
  Timer? _timer;

  Duration _base = Duration.zero; // Temps acumulat abans de l'últim start
  Duration _elapsed = Duration.zero; // Temps des de l'últim start

  @override
  Duration build() => Duration.zero;

  // Total = base + elapsed
  Duration get total => _base + _elapsed;

  void start() {
    _timer?.cancel();
    _elapsed = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      state = total; // Exposem el total en viu
    });
  }

  void pause() {
    _timer?.cancel();
    _base += _elapsed; // Guardem el temps acumulat
    _elapsed = Duration.zero;
    state = total;
  }

  void resume() {
    start(); // Reengega el timer mantenint _base
  }

  void reset() {
    _timer?.cancel();
    _base = Duration.zero;
    _elapsed = Duration.zero;
    state = Duration.zero;
  }

  void setInitialValue(Duration duration) {
    _base = duration;
    _elapsed = Duration.zero;
    state = duration;
  }
}

final timerProvider = NotifierProvider<TimerNotifier, Duration>(
  TimerNotifier.new,
);
