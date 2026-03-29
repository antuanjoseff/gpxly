import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track.dart';

/// Notifier modern amb gravació GPS en background
class TrackNotifier extends Notifier<Track> {
  ReceivePort? _receivePort;

  @override
  Track build() {
    return Track(coordinates: [], altitudes: [], timestamps: []);
  }

  /// Inicia la gravació automàtica del track en foreground service
  Future<void> startRecording() async {
    await stopRecording();

    // Crear port per rebre dades del servei
    _receivePort = ReceivePort();

    // Registrar-lo perquè el servei el pugui trobar
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'gpxly_port',
    );

    // Escoltar dades enviades des del servei
    _receivePort!.listen((data) {
      if (data is Map<String, dynamic>) {
        final pos = Position(
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: data['altitude'] as double,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
          isMocked: false,
        );
        addPointFromPosition(pos);
      }
    });

    // Iniciar servei de foreground
    await FlutterForegroundTask.startService(
      notificationTitle: 'GPXly registrant track',
      notificationText: 'Gravant GPS en background',
      callback: startCallback,
    );
  }

  /// Para la gravació
  Future<void> stopRecording() async {
    await FlutterForegroundTask.stopService();

    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping('gpxly_port');
      _receivePort!.close();
      _receivePort = null;
    }
  }

  /// Afegeix un punt donat un Position
  void addPointFromPosition(Position pos) {
    final now = DateTime.now();
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [pos.latitude, pos.longitude],
      ],
      altitudes: [...state.altitudes, pos.altitude],
      timestamps: [...state.timestamps, now],
    );
  }

  /// Reinicia el track
  void reset() {
    state = Track(coordinates: [], altitudes: [], timestamps: []);
  }
}

/// Provider modern de Riverpod
final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);

/// Callback del Foreground Service
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundTaskHandler());
}

/// Handler del foreground task
class BackgroundTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStreamSub;
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sendPort = IsolateNameServer.lookupPortByName('gpxly_port');

    // GPS
    _positionStreamSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          _sendPort?.send({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'altitude': pos.altitude,
          });
        });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isAppTerminated) async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  Future<void> onEvent(DateTime timestamp) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  void onButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
