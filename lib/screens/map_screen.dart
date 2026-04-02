import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:gpxly/notifiers/gps_settings_provider.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/screens/gps_settings_screen.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/widgets/map_buttons.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapLibreMapController? mapController;
  bool styleInitialized = false;
  bool userMovedMap = false;
  DateTime? _lastBackPress;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  LatLng? _lastPosition;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final track = ref.read(trackProvider);
      if (track.coordinates.isNotEmpty) {
        final last = track.coordinates.last;
        _saveLastPosition(last[1], last[0]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);

    // Listener dins build (Riverpod obliga)
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;
      if (next.coordinates.isEmpty) return;

      final last = next.coordinates.last;
      final lon = last[0];
      final lat = last[1];

      try {
        animateLastSegment(
          lat: lat,
          lon: lon,
          allCoordinates: next.coordinates,
          controller: mapController!,
          userMovedMap: userMovedMap,
          currentLastPosition: _lastPosition,
          currentTimer: _animationTimer,
          setLastPosition: (p) => _lastPosition = p,
          setTimer: (t) => _animationTimer = t,
        );
      } catch (_) {}
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;

          AppMessages.showExitWarning(context);
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Mapa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.gps_fixed),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GpsSettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MapLibreMap(
              styleString: "assets/osm_style.json",
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 14,
              ),
              onMapCreated: (controller) => mapController = controller,
              onCameraMove: (_) => userMovedMap = true,
              onStyleLoadedCallback: () async {
                await setupUserLocationLayer(mapController!);
                styleInitialized = true;

                final prefs = await SharedPreferences.getInstance();
                final lat = prefs.getDouble("last_lat");
                final lon = prefs.getDouble("last_lon");

                if (lat != null && lon != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(lat, lon)),
                  );
                }

                updateMapPosition(mapController!, lat ?? 0, lon ?? 0);

                final track = ref.read(trackProvider);

                if (track.coordinates.isNotEmpty) {
                  final last = track.coordinates.last;

                  updateMapPosition(mapController!, last[1], last[0]);

                  mapController!.setGeoJsonSource("track_line", {
                    "type": "FeatureCollection",
                    "features": [
                      {
                        "type": "Feature",
                        "geometry": {
                          "type": "LineString",
                          "coordinates": track.coordinates,
                        },
                      },
                    ],
                  });
                }
              },
            ),

            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  "${track.formattedDuration} (${track.coordinates.length} punts)",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),

            // -------------------------
            // BOTÓ PRINCIPAL
            // -------------------------
            Positioned(
              bottom: 40,
              right: 20,
              child: StartPauseResumeButton(
                track: track,
                onStart: () async => await _startRecording(),
                onPause: () async => await _pauseRecording(),
                onResume: () async => await _resumeRecording(),
              ),
            ),

            // -------------------------
            // BOTÓ STOP
            // -------------------------
            if (track.recording && track.paused)
              Positioned(
                bottom: 120,
                right: 20,
                child: StopButton(onStop: () async => await _stopRecording()),
              ),

            // -------------------------
            // BOTÓ CENTER
            // -------------------------
            Positioned(
              bottom: 200,
              right: 20,
              child: FloatingActionButton(
                heroTag: "center",
                backgroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
                onPressed: () {
                  userMovedMap = false;
                  if (track.coordinates.isNotEmpty && mapController != null) {
                    final last = track.coordinates.last;
                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(LatLng(last[1], last[0])),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // FUNCIONS DE GRAVACIÓ
  // -------------------------

  Future<void> _startRecording() async {
    final notifier = ref.read(trackProvider.notifier);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;

      final activate = await AppMessages.showGpsDisabledDialog(context);
      if (activate == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    final ok = await PermissionsService.ensurePermissions(context);
    if (!context.mounted || !ok) return;

    _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
      double lat = data['lat'] as double;
      double lon = data['lon'] as double;

      // lat += randomOffset(50);
      // lon += randomOffset(50);

      notifier.addCoordinate(lat, lon);
    });

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    final pos = await Geolocator.getCurrentPosition();
    notifier.addCoordinate(pos.latitude, pos.longitude);

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    }

    notifier.startRecording(context);
  }

  Future<void> _pauseRecording() async {
    final notifier = ref.read(trackProvider.notifier);
    notifier.pauseRecording();
    await NativeGpsChannel.stop();
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<void> _resumeRecording() async {
    final notifier = ref.read(trackProvider.notifier);
    notifier.resumeRecording();

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
      double lat = data['lat'] as double;
      double lon = data['lon'] as double;

      // lat += randomOffset(50);
      // lon += randomOffset(50);

      notifier.addCoordinate(lat, lon);
    });
  }

  Future<void> _stopRecording() async {
    final notifier = ref.read(trackProvider.notifier);

    notifier.stopRecording();
    await NativeGpsChannel.stop();
    await _gpsSub?.cancel();
    _gpsSub = null;

    final export = await AppMessages.showExportDialog(context);

    if (export == true) {
      final filename = buildGpxFilename();
      await exportGpx(filename, ref, context);
    }
  }

  Future<void> _saveLastPosition(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("last_lat", lat);
    await prefs.setDouble("last_lon", lon);
  }
}
