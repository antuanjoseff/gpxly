import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../models/track.dart';

class TrackNotifier extends Notifier<Track> {
  ReceivePort? _receivePort;
  Timer? _timer;

  @override
  Track build() {
    return Track(
      coordinates: [],
      altitudes: [],
      timestamps: [],
      recording: false,
      duration: Duration.zero,
    );
  }

  Future<void> startRecording() async {
    await stopRecording();

    // 1. Permisos
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    // 2. Estat inicial
    state = state.copyWith(
      recording: true,
      duration: Duration.zero,
      coordinates: [],
      altitudes: [],
      timestamps: [],
    );

    // 3. Timer per comptar el temps
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.recording) {
        state = state.copyWith(
          duration: state.duration + const Duration(seconds: 1),
        );
      }
    });

    // 4. Crear port per rebre dades del servei
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      'gpxly_port',
    );

    // 5. Escoltar dades del servei
    _receivePort!.listen((data) {
      if (data is Map<String, dynamic>) {
        addPointFromPosition(
          Position(
            latitude: data['latitude'],
            longitude: data['longitude'],
            altitude: data['altitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
            isMocked: false,
          ),
        );
      }
    });

    // 6. Iniciar servei de foreground
    await FlutterForegroundTask.startService(
      notificationTitle: 'GPXly registrant track',
      notificationText: 'Gravant GPS en background',
      callback: startCallback,
    );
  }

  void addCoordinate(double lat, double lon) {
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [lon, lat], // GeoJSON = [lon, lat]
      ],
    );
  }

  Future<void> stopRecording() async {
    await FlutterForegroundTask.stopService();

    state = state.copyWith(recording: false);

    _timer?.cancel();
    _timer = null;

    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping('gpxly_port');
      _receivePort!.close();
      _receivePort = null;
    }
  }

  void addPointFromPosition(Position pos) {
    final now = DateTime.now();
    state = state.copyWith(
      coordinates: [
        ...state.coordinates,
        [pos.longitude, pos.latitude], // ✔ CORRECTE
      ],
      altitudes: [...state.altitudes, pos.altitude],
      timestamps: [...state.timestamps, now],
    );
  }

  void reset() {
    state = Track(
      coordinates: [],
      altitudes: [],
      timestamps: [],
      recording: false,
      duration: Duration.zero,
    );
  }
}

final trackProvider = NotifierProvider<TrackNotifier, Track>(TrackNotifier.new);

void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundTaskHandler());
}

class BackgroundTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStreamSub;
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sendPort = IsolateNameServer.lookupPortByName('gpxly_port');

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

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Pots deixar-ho buit
  }

  @override
  void onNotificationPressed() {
    // Pots deixar-ho buit
  }
}
