import 'dart:async';

import 'package:flutter/services.dart';

class NativeBarometerChannel {
  static const _methods = MethodChannel('barometer_methods');
  static const _events = EventChannel('barometer_stream');

  static Stream<double>? _pressureStream;

  static Future<void> start() async {
    await _methods.invokeMethod('start');
  }

  static Future<void> stop() async {
    await _methods.invokeMethod('stop');
  }

  static Stream<double> pressureStream() {
    _pressureStream ??= _events.receiveBroadcastStream().map(
      (event) => event as double,
    );
    return _pressureStream!;
  }
}
