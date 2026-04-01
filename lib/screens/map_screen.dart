import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'dart:math';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? mapController;
  bool styleInitialized = false;
  bool userMovedMap = false;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  LatLng? _lastPosition;
  Timer? _animationTimer;

  @override
  void dispose() {
    _animationTimer?.cancel();
    _gpsSub?.cancel();
    super.dispose();
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

    return Scaffold(
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
            child: FloatingActionButton(
              backgroundColor: track.recording ? Colors.red : Colors.green,
              child: Icon(track.recording ? Icons.stop : Icons.play_arrow),
              onPressed: () async {
                final notifier = ref.read(trackProvider.notifier);

                if (!track.recording) {
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

                    // Error aleatori de fins a ~5 metres
                    lat += randomOffset(5);
                    lon += randomOffset(5);

                    notifier.addCoordinate(lat, lon);
                  });

                  await NativeGpsChannel.start();

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
                } else {
                  // 🔹 Aturem la gravació
                  notifier.stopRecording();
                  await NativeGpsChannel.stop();
                  await _gpsSub?.cancel();
                  _gpsSub = null;
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

    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      const steps = 10;
      int currentStep = 0;

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
}
