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
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:gpxly/widgets/gps_accuracy_bars.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/notifiers/gps_accuracy_provider.dart';

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
  Timer? _cameraMoveDebounce;
  bool isProgrammaticMove = false;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  LatLng? _lastPosition;
  Timer? _animationTimer;

  final ButtonStyle recordButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.all(16),
    elevation: 6,
  );

  final TextStyle recordLabelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

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

  void _onMapChanged() {
    if (isProgrammaticMove) return; // 👈 CLAU

    final moving = mapController?.isCameraMoving ?? false;

    if (moving) {
      _cameraMoveDebounce?.cancel();
      _cameraMoveDebounce = Timer(const Duration(milliseconds: 150), () {
        userMovedMap = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);

    // Listener dins build (Riverpod obliga)
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;
      if (next.coordinates.isEmpty) return;

      final last = next.coordinates.last;
      final lon = last[0];
      final lat = last[1];

      // 🔵 PRIMERA COORDENADA → dibuix immediat
      if (next.coordinates.length == 1) {
        updateMapPosition(mapController!, lat, lon);

        // També cal dibuixar la línia (buida o amb 1 punt)
        mapController!.setGeoJsonSource("track_line", {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": next.coordinates,
              },
            },
          ],
        });

        return;
      }

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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GpsAccuracyBars(),
                  const SizedBox(width: 4),
                  // Només mostrem el text si hi ha dades reals
                  if (accuracy != 999)
                    Text(
                      accuracy == 999 ? "?" : "${accuracy.round()} m",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
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
              trackCameraPosition: true,
              styleString: "assets/osm_style.json",
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 14,
              ),
              // onCameraMove: (position) {
              //   if (isProgrammaticMove) {
              //     return;
              //   }

              //   // 👉 Això sí que és usuari
              //   userMovedMap = true;
              // },
              onCameraMove: (position) {
                if (isProgrammaticMove) return;
                userMovedMap = true;
              },
              onMapCreated: (controller) {
                mapController = controller;
                controller.addListener(_onMapChanged);
              },
              onStyleLoadedCallback: () async {
                await setupUserLocationLayer(mapController!);
                styleInitialized = true;

                final prefs = await SharedPreferences.getInstance();
                final lat = prefs.getDouble("last_lat");
                final lon = prefs.getDouble("last_lon");

                if (lat != null && lon != null) {
                  print("PROGRAMMATIC MOVE → animateCamera()");
                  isProgrammaticMove = true;
                  mapController!
                      .animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon)))
                      .then((_) => isProgrammaticMove = false);
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
            // -------------------------
            // BOTÓ PRINCIPAL
            // -------------------------
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(
                        24,
                      ), // ajusta segons el que vulguis
                      elevation: 6,
                    ),
                    onPressed: () {
                      if (!track.recording) {
                        _startRecording();
                      } else if (track.paused) {
                        _resumeRecording();
                      } else {
                        _pauseRecording();
                      }
                    },
                    child: Icon(
                      track.recording
                          ? (track.paused ? Icons.play_arrow : Icons.pause)
                          : Icons.fiber_manual_record,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.recording
                        ? (track.paused ? "Pausat" : "Gravant...")
                        : "Gravant...",
                    style: recordLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  // Botó de compartir només si està gravant i pausat
                  if (track.recording && track.paused)
                    ElevatedButton.icon(
                      onPressed: _shareTrack,
                      icon: const Icon(Icons.share),
                      label: const Text("Compartir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
            // -------------------------
            // BOTÓ CENTER
            // -------------------------
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: "center",
                backgroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
                onPressed: () async {
                  if (track.coordinates.isEmpty || mapController == null)
                    return;

                  final last = track.coordinates.last;

                  print("PROGRAMMATIC MOVE → animateCamera()");

                  isProgrammaticMove = true;
                  userMovedMap = false; // 👈 reset correcte

                  await mapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(last[1], last[0])),
                  );

                  isProgrammaticMove = false;
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
    print("GPXLY START RECORDING");

    final pos = await Geolocator.getCurrentPosition();
    notifier.addCoordinate(pos.latitude, pos.longitude);
    ref.read(gpsAccuracyProvider.notifier).state = pos.accuracy;

    _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
      double lat = data['lat'] as double;
      double lon = data['lon'] as double;
      double acc = data['accuracy'] as double;
      // lat += randomOffset(50);
      // lon += randomOffset(50);
      print("GPXLY ACCURACY CHANGED ${acc}");
      notifier.addCoordinate(lat, lon);
      ref.read(gpsAccuracyProvider.notifier).state = acc;
    });

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    if (mapController != null) {
      isProgrammaticMove = true;
      mapController!
          .animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
          )
          .then((_) => isProgrammaticMove = false);
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

  Future<void> _shareTrack() async {
    final track = ref.read(trackProvider);

    if (track.coordinates.isEmpty) return;

    // Exporta i comparteix amb la funció que ja tens
    final filename = buildGpxFilename();
    await exportGpx(filename, ref, context);

    if (!mounted) return;

    // Diàleg després de compartir
    final reset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vols reiniciar el track?"),
        content: const Text(
          "Si continues, el track seguirà sumant punts.\n"
          "Si reinicies, s'esborrarà tota la informació actual.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Continuar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reiniciar"),
          ),
        ],
      ),
    );

    if (reset == true) {
      ref.read(trackProvider.notifier).reset();
      setState(() {});
    } else {
      setState(() {});
    }
  }
}
