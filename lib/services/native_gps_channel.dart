import 'dart:async';
import 'package:flutter/services.dart';

class NativeGpsChannel {
  static const MethodChannel _methods = MethodChannel('tracking/methods');
  static const EventChannel _events = EventChannel('tracking/events');

  // Stream base compartido que escucha la tubería nativa de Android
  static Stream<Map<String, dynamic>>? _rawEventStream;

  static Stream<Map<String, dynamic>> _getRawStream() {
    _rawEventStream ??= _events.receiveBroadcastStream().map((event) {
      final map = Map<dynamic, dynamic>.from(event);
      return map.map((k, v) => MapEntry(k.toString(), v));
    });
    return _rawEventStream!;
  }

  // 1. MÉTODOS DE CONTROL (Se quedan igual, respetando tus dobles)
  static Future<void> start({
    required bool useTime,
    required int seconds,
    required double meters,
    required double accuracy,
    required bool debug,
  }) async {
    await _methods.invokeMethod('start', {
      'useTime': useTime,
      'seconds': seconds,
      'meters': meters,
      'accuracy': accuracy,
      'debug': debug,
    });
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

  static Future<bool> isIgnoringBatteryOptimizations() async {
    final res = await _methods.invokeMethod<bool>(
      'isIgnoringBatteryOptimizations',
    );
    return res ?? true;
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final res = await _methods.invokeMethod<bool>(
      'requestIgnoreBatteryOptimizations',
    );
    return res ?? false;
  }

  // 2. STREAM DE UBICACIÓN (Filtra y se queda solo con los puntos del mapa)
  static Stream<Map<String, dynamic>> get locationStream {
    return _getRawStream().where((event) => !event.containsKey('type'));
  }

  // 3. NUEVO STREAM DE SATÉLITES (Filtra y se queda solo con el estado del GNSS)
  static Stream<List<dynamic>> get satelliteStream {
    return _getRawStream()
        .where((event) => event['type'] == 'gnss_status')
        .map((event) => event['satellites'] as List<dynamic>);
  }

  // 4. STREAM DE DEBUG GPS (Drops, lots, resums, etc.)
  static Stream<Map<String, dynamic>> get debugStream {
    return _getRawStream().where((event) => event['type'] == 'gps_debug');
  }
}
