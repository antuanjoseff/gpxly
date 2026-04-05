import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/gps_accuracy.dart';

class GpsAccuracyNotifier extends Notifier<double> {
  @override
  double build() => 999.0;

  void update(double value) {
    state = value;
  }
}

final gpsAccuracyProvider = NotifierProvider<GpsAccuracyNotifier, double>(
  GpsAccuracyNotifier.new,
);

final gpsAccuracyLevelProvider = Provider<GpsAccuracyLevel>((ref) {
  final acc = ref.watch(gpsAccuracyProvider);
  return getAccuracyLevel(acc);
});
