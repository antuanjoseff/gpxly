import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsAltitudeNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void update(double value) {
    state = value;
  }
}

final gpsAltitudeProvider = NotifierProvider<GpsAltitudeNotifier, double>(
  GpsAltitudeNotifier.new,
);
