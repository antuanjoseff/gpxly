import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapBearingNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void update(double value) {
    state = value;
  }
}

final mapBearingProvider = NotifierProvider<MapBearingNotifier, double>(
  MapBearingNotifier.new,
);
