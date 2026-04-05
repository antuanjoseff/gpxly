import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsBearingNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void update(double value) {
    state = value;
  }
}

final gpsBearingProvider = NotifierProvider<GpsBearingNotifier, double>(
  GpsBearingNotifier.new,
);
