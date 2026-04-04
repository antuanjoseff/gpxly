import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../utils/gps_accuracy.dart';

final gpsAccuracyProvider = StateProvider<double>((ref) => 999);

final gpsAccuracyLevelProvider = Provider<GpsAccuracyLevel>((ref) {
  final acc = ref.watch(gpsAccuracyProvider);
  return getAccuracyLevel(acc);
});

// Provider per a l'elevació actual (alçada)
final gpsAltitudeProvider = StateProvider<double?>((ref) => null);
