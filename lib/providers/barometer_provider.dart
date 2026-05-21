import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/services/native_barometer_channel.dart';

final barometerProvider = StreamProvider<double>((ref) {
  return NativeBarometerChannel.pressureStream();
});

double pressureToAltitude(double pressure) {
  return 44330.0 * (1.0 - pow(pressure / 1013.25, 0.1903));
}

final baroAltitudeProvider = Provider<double?>((ref) {
  final pressure = ref.watch(barometerProvider).value;
  if (pressure == null) return null;
  return pressureToAltitude(pressure);
});
