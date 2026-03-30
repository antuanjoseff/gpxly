import 'dart:async';
import 'package:flutter/services.dart';

class NativeGpsChannel {
  static const MethodChannel _method = MethodChannel("tracking/methods");
  static const EventChannel _events = EventChannel("tracking/events");

  static Stream<Map<String, dynamic>> get locationStream {
    return _events.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }

  static Future<void> start() async {
    await _method.invokeMethod("start");
  }

  static Future<void> stop() async {
    await _method.invokeMethod("stop");
  }

  static Future<void> openAppLocationPermissions() async {
    await _method.invokeMethod("openAppLocationPermissions");
  }

  /// 🔥 Comprovar permís ALWAYS real via Android
  static Future<bool> hasBackgroundPermission() async {
    final result = await _method.invokeMethod<bool>("hasBackgroundPermission");
    return result ?? false;
  }

  /// 🔥 Demanar explícitament ACCESS_BACKGROUND_LOCATION (Samsung ho exigeix)
  static Future<void> requestBackgroundPermission() async {
    await _method.invokeMethod("requestBackgroundPermission");
  }
}
