import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsSpeedNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void update(double value) {
    state = value;
  }
}

final gpsSpeedProvider = NotifierProvider<GpsSpeedNotifier, double>(
  GpsSpeedNotifier.new,
);

final mapZoomProvider = NotifierProvider<GpsSpeedNotifier, double>(
  GpsSpeedNotifier.new,
);

final mapCenterLatProvider = NotifierProvider<GpsSpeedNotifier, double>(
  GpsSpeedNotifier.new,
);
