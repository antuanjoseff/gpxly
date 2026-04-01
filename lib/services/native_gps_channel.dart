import 'dart:async';
import 'package:flutter/services.dart';

class NativeGpsChannel {
  static const MethodChannel _methods = MethodChannel('tracking/methods');

  static const EventChannel _events = EventChannel('tracking/events');

  static Stream<Map<String, dynamic>>? _positionStream;

  static Stream<Map<String, dynamic>>? _locationStream;

  static Future<void> start() async {
    await _methods.invokeMethod('start');
  }

  static Future<void> stop() async {
    await _methods.invokeMethod('stop');
  }

  static Future<bool> hasBackgroundPermission() async {
    final res = await _methods.invokeMethod<bool>('hasBackgroundPermission');
    return res ?? false;
  }

  static Future<bool> requestBackgroundPermission() async {
    final res = await _methods.invokeMethod<bool>(
      'requestBackgroundPermission',
    );
    return res ?? false;
  }

  static Stream<Map<String, dynamic>> positionStream() {
    _positionStream ??= _events.receiveBroadcastStream().map((event) {
      final map = Map<dynamic, dynamic>.from(event);
      return map.map((k, v) => MapEntry(k.toString(), v));
    });
    return _positionStream!;
  }

  static Stream<Map<String, dynamic>> get locationStream {
    _locationStream ??= _events.receiveBroadcastStream().map((event) {
      final map = Map<dynamic, dynamic>.from(event);
      return map.map((k, v) => MapEntry(k.toString(), v));
    });
    return _locationStream!;
  }
}
