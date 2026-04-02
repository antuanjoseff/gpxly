import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/gps_settings_provider.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/screens/gps_settings_screen.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  double _computeSpeed(
    double lat1,
    double lon1,
    DateTime t1,
    double lat2,
    double lon2,
    DateTime t2,
  ) {
    final distance = Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    ); // metres
    final dt = t2.difference(t1).inMilliseconds / 1000.0; // segons
    if (dt <= 0) return 0;
    return distance / dt; // m/s
  }

  Map<String, double> _computeBounds(List<List<double>> coords) {
    double minLat = 90, maxLat = -90;
    double minLon = 180, maxLon = -180;

    for (final c in coords) {
      final lon = c[0];
      final lat = c[1];

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }

    return {
      "minlat": minLat,
      "minlon": minLon,
      "maxlat": maxLat,
      "maxlon": maxLon,
    };
  }

  String _buildGpxFilename() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return "Track-gpxly-$y-$m-$d.gpx";
  }

  Future<void> exportGpx(
    BuildContext context,
    String filename,
    WidgetRef ref,
  ) async {
    final track = ref.read(trackProvider);

    if (track.coordinates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hi ha cap track per exportar")),
        );
      }
      return;
    }

    final coords = track.coordinates;
    final alts = track.altitudes;
    final times = track.timestamps;

    final bounds = _computeBounds(coords);

    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Gpxly">');

    buffer.writeln(
      '<bounds minlat="${bounds["minlat"]}" minlon="${bounds["minlon"]}" '
      'maxlat="${bounds["maxlat"]}" maxlon="${bounds["maxlon"]}" />',
    );

    buffer.writeln('<trk><name>$filename</name><trkseg>');

    for (int i = 0; i < coords.length; i++) {
      final lon = coords[i][0];
      final lat = coords[i][1];

      final ele = (i < alts.length) ? alts[i] : 0.0;
      final time = (i < times.length)
          ? times[i].toUtc().toIso8601String()
          : null;

      double speed = 0;
      if (i > 0 && i < times.length) {
        speed = _computeSpeed(
          coords[i - 1][1],
          coords[i - 1][0],
          times[i - 1],
          lat,
          lon,
          times[i],
        );
      }

      buffer.writeln('<trkpt lat="$lat" lon="$lon">');
      buffer.writeln('<ele>$ele</ele>');
      if (time != null) buffer.writeln('<time>$time</time>');
      buffer.writeln('<speed>$speed</speed>');
      buffer.writeln('</trkpt>');
    }

    buffer.writeln('</trkseg></trk></gpx>');

    // 🔥 Guardar temporalment i compartir
    final dir = await getTemporaryDirectory();
    final safeName = filename.endsWith(".gpx") ? filename : "$filename.gpx";
    final file = File("${dir.path}/$safeName");

    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: "GPX exportat");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("GPX preparat per compartir: $safeName")),
      );
    }
  }

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
        _animateLastSegment(lat, lon, next.coordinates);
      } catch (_) {}
    });

    return PopScope(
      canPop: false, // molt important: tu controles el back
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;

          AppMessages.showExitWarning(context);
          return;
        }

        // Segon back → sortir de l’app
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Mapa'), // Opcional, pots deixar només la icona
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
                await _setupUserLocationLayer();
                styleInitialized = true;
                final prefs = await SharedPreferences.getInstance();
                final lat = prefs.getDouble("last_lat");
                final lon = prefs.getDouble("last_lon");

                if (lat != null && lon != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(lat, lon)),
                  );
                }
                _updateMapPosition(lat ?? 0, lon ?? 0);
                final track = ref.read(trackProvider);

                if (track.coordinates.isNotEmpty) {
                  final last = track.coordinates.last;

                  // Dibuixa el punt blau
                  _updateMapPosition(last[1], last[0]);

                  // Dibuixa la línia sencera
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

            Positioned(
              bottom: 40,
              right: 20,
              child: StartPauseResumeButton(
                track: track,

                onStart: () async {
                  final notifier = ref.read(trackProvider.notifier);

                  // 🔹 Comprovem si el GPS està activat
                  final serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if (!context.mounted) return;

                    final activate = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('GPS desactivat'),
                        content: const Text(
                          'El GPS està desactivat. Vols activar-lo ara?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel·lar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Obrir configuració'),
                          ),
                        ],
                      ),
                    );

                    if (activate == true) {
                      await Geolocator.openLocationSettings();
                    }

                    return;
                  }

                  // 🔹 Comprovem permisos
                  final ok = await PermissionsService.ensurePermissions(
                    context,
                  );
                  if (!context.mounted || !ok) return;

                  // 🔹 Subscrivim al stream del GPS
                  _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
                    double lat = data['lat'] as double;
                    double lon = data['lon'] as double;

                    lat += randomOffset(50);
                    lon += randomOffset(50);

                    notifier.addCoordinate(lat, lon);
                  });

                  final settings = ref.read(gpsSettingsProvider);
                  await NativeGpsChannel.start(
                    useTime: settings.useTime,
                    seconds: settings.seconds,
                    meters: settings.meters,
                    accuracy: settings.accuracy,
                  );

                  // 🔹 Afegim la posició inicial
                  final pos = await Geolocator.getCurrentPosition();
                  notifier.addCoordinate(pos.latitude, pos.longitude);

                  if (mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(pos.latitude, pos.longitude),
                      ),
                    );
                  }

                  notifier.startRecording(context);
                },

                onPause: () async {
                  final notifier = ref.read(trackProvider.notifier);
                  notifier.pauseRecording();
                  await NativeGpsChannel.stop();
                  await _gpsSub?.cancel();
                  _gpsSub = null;
                },

                onResume: () async {
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

                    lat += randomOffset(50);
                    lon += randomOffset(50);

                    notifier.addCoordinate(lat, lon);
                  });
                },
              ),
            ),

            if (track.recording && track.paused)
              Positioned(
                bottom: 120,
                right: 20,
                child: StopButton(
                  onStop: () async {
                    final notifier = ref.read(trackProvider.notifier);

                    notifier.stopRecording();
                    await NativeGpsChannel.stop();
                    await _gpsSub?.cancel();
                    _gpsSub = null;

                    final export = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Exportar GPX"),
                        content: const Text("Vols exportar el track ara?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel·lar"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Exportar"),
                          ),
                        ],
                      ),
                    );

                    if (export == true) {
                      final filename = _buildGpxFilename();
                      await _exportGpx(filename);
                    }
                  },
                ),
              ),

            Positioned(
              bottom: 120,
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

  // ---------------------
  // Animació suau últim segment
  // ---------------------
  void _animateLastSegment(
    double lat,
    double lon,
    List<List<double>> allCoordinates,
  ) {
    if (mapController == null) return;

    final newPos = LatLng(lat, lon);

    // 🔹 Només animar si la posició real ha canviat
    if (_lastPosition != null &&
        _lastPosition!.latitude == newPos.latitude &&
        _lastPosition!.longitude == newPos.longitude) {
      return; // mateixa posició, no animem
    }

    // 🔹 No reiniciem animació si ja hi ha un Timer actiu
    if (_animationTimer != null && _animationTimer!.isActive) return;

    if (allCoordinates.length < 2) {
      // Primer punt
      _lastPosition = newPos;
      _updateMapPosition(lat, lon);
      mapController!.setGeoJsonSource("track_line", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": allCoordinates},
          },
        ],
      });
      return;
    }

    final fullTrack = List<List<double>>.from(allCoordinates);
    final penultimate = fullTrack[fullTrack.length - 2];
    final startLat = penultimate[1];
    final startLon = penultimate[0];

    int currentStep = 0;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      const steps = 10;

      currentStep++;

      final deltaLat = (lat - startLat) / steps;
      final deltaLon = (lon - startLon) / steps;

      final animatedLat = startLat + deltaLat * currentStep;
      final animatedLon = startLon + deltaLon * currentStep;

      // Punt blau
      _updateMapPosition(animatedLat, animatedLon);

      // Track complet fins al penúltim + punt interpolat
      final animatedCoordinates = [
        ...fullTrack.sublist(0, fullTrack.length - 1),
        [animatedLon, animatedLat],
      ];

      mapController!.setGeoJsonSource("track_line", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": animatedCoordinates,
            },
          },
        ],
      });

      if (currentStep >= steps) {
        timer.cancel();
        _lastPosition = newPos;

        // Només ara fem animació de la càmera un cop
        if (!userMovedMap) {
          mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
        }
      }
    });
  }

  void _updateMapPosition(double lat, double lon) {
    if (mapController == null) return;

    mapController!.setGeoJsonSource("user_location", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lon, lat],
          },
        },
      ],
    });

    // NO fem moveCamera cada frame de l’animació
    // El seguiment el farem després de la interpolació
  }

  // ---------------------
  // Configuració del punt i línia
  // ---------------------
  Future<void> _setupUserLocationLayer() async {
    if (mapController == null) return;

    await mapController!.addSource(
      "track_line",
      GeojsonSourceProperties(
        data: {"type": "FeatureCollection", "features": []},
      ),
    );

    await mapController!.addLayer(
      "track_line",
      "track_line_layer",
      const LineLayerProperties(
        lineColor: "#FF0000",
        lineWidth: 4.0,
        lineJoin: "round",
        lineCap: "round",
      ),
    );

    final Uint8List blueDot = await _createBlueDot();
    await mapController!.addImage("user_icon", blueDot);

    await mapController!.addSource(
      "user_location",
      GeojsonSourceProperties(
        data: {"type": "FeatureCollection", "features": []},
      ),
    );

    await mapController!.addLayer(
      "user_location",
      "user_location_layer",
      const SymbolLayerProperties(iconImage: "user_icon", iconSize: 1.0),
    );
  }

  Future<Uint8List> _createBlueDot() async {
    const int size = 64;
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  double randomOffset(double meters) {
    // Converteix metres aproximadament a graus
    const meterInDegree = 1 / 111320.0;
    final r = Random().nextDouble() * 2 - 1; // [-1, 1]
    return r * meters * meterInDegree;
  }

  Future<void> _saveLastPosition(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("last_lat", lat);
    await prefs.setDouble("last_lon", lon);
  }
}

class StartPauseResumeButton extends StatelessWidget {
  final Track track;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;

  const StartPauseResumeButton({
    super.key,
    required this.track,
    required this.onStart,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = track.recording;
    final isPaused = track.paused;

    final color = !isRecording
        ? Colors
              .green // START
        : isPaused
        ? Colors
              .green // RESUME
        : Colors.orange; // PAUSE

    final icon = !isRecording
        ? Icons.play_arrow
        : isPaused
        ? Icons.play_arrow
        : Icons.pause;

    return FloatingActionButton(
      backgroundColor: color,
      child: Icon(icon),
      onPressed: () async {
        if (!isRecording) {
          await onStart();
          return;
        }
        if (!isPaused) {
          await onPause();
          return;
        }
        await onResume();
      },
    );
  }
}

class StopButton extends StatelessWidget {
  final Future<void> Function() onStop;

  const StopButton({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      child: const Icon(Icons.stop),
      onPressed: () async => await onStop(),
    );
  }
}
