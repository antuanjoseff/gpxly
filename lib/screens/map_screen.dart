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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? mapController;
  bool styleInitialized = false;
  bool userMovedMap = false;
  bool listenerAttached = false;
  bool checkingPermissions = false;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(">>> MapScreen.build()");
    final track = ref.watch(trackProvider);

    // Attach listener només una vegada
    if (!listenerAttached) {
      listenerAttached = true;

      ref.listen(trackProvider, (previous, next) {
        print(">>> TRACK SIZE = ${next.coordinates.length}");
        if (!styleInitialized || mapController == null) return;
        if (next.coordinates.isEmpty) return;

        final last = next.coordinates.last;
        final lon = last[0];
        final lat = last[1];

        try {
          // Actualitzar punt d’usuari
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

          // Actualitzar línia del track
          mapController!.setGeoJsonSource("track_line", {
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "LineString",
                  "coordinates": next.coordinates, // ja és [lon, lat]
                },
              },
            ],
          });
        } catch (_) {
          // Si la source encara no existeix (p.e. després d’un reload d’estil), no matem el mapa
          return;
        }

        // Centrar mapa si l’usuari no l’ha mogut
        if (!userMovedMap) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lon)),
          );
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: "assets/osm_style.json",
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            onCameraMove: (_) {
              userMovedMap = true;
            },
            onStyleLoadedCallback: () async {
              await _setupUserLocationLayer();
              styleInitialized = true;
            },
          ),

          // NAVBAR
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                track.formattedDuration,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // BOTÓ INICIAR / PARAR
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: track.recording ? Colors.red : Colors.green,
              child: Icon(track.recording ? Icons.stop : Icons.play_arrow),
              onPressed: () async {
                print(">>> BUTTON PRESSED");
                final notifier = ref.read(trackProvider.notifier);

                if (!track.recording) {
                  // 0. Permisos complets
                  final ok = await PermissionsService.ensurePermissions(
                    context,
                  );
                  if (!context.mounted) return;
                  if (!ok) return;

                  // 1. Activar escolta d’events del servei natiu
                  _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
                    final lat = data['lat'] as double;
                    final lon = data['lon'] as double;

                    notifier.addCoordinate(lat, lon);

                    if (styleInitialized && mapController != null) {
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

                      if (!userMovedMap) {
                        mapController!.animateCamera(
                          CameraUpdate.newLatLng(LatLng(lat, lon)),
                        );
                      }
                    }
                  });

                  // 2. Iniciar servei natiu
                  await NativeGpsChannel.start();

                  // 3. Opcional: posició inicial immediata
                  final pos = await Geolocator.getCurrentPosition();
                  notifier.addCoordinate(pos.latitude, pos.longitude);

                  if (mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(pos.latitude, pos.longitude),
                      ),
                    );
                  }

                  // 4. Iniciar gravació (timer, etc.)
                  notifier.startRecording(context);
                } else {
                  // Aturar gravació
                  notifier.stopRecording();
                  await NativeGpsChannel.stop();
                  await _gpsSub?.cancel();
                  _gpsSub = null;
                }
              },
            ),
          ),

          // BOTÓ CENTRAR-ME
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              heroTag: "center",
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
              onPressed: () {
                userMovedMap = false; // tornem al mode auto
                if (track.coordinates.isNotEmpty && mapController != null) {
                  final last = track.coordinates.last;
                  final lon = last[0];
                  final lat = last[1];
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(lat, lon)),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Configura la font i capes per mostrar el punt de l’usuari i la línia del track
  Future<void> _setupUserLocationLayer() async {
    if (mapController == null) return;

    // 1. Crear icona en memòria
    final Uint8List blueDot = await _createBlueDot();
    await mapController!.addImage("user_icon", blueDot);

    // 2. SOURCE del punt
    await mapController!.addSource(
      "user_location",
      GeojsonSourceProperties(
        data: {"type": "FeatureCollection", "features": []},
      ),
    );

    // 3. CAPA del punt
    await mapController!.addLayer(
      "user_location",
      "user_location_layer",
      const SymbolLayerProperties(iconImage: "user_icon", iconSize: 1.0),
    );

    // 4. SOURCE de la línia del track
    await mapController!.addSource(
      "track_line",
      GeojsonSourceProperties(
        data: {"type": "FeatureCollection", "features": []},
      ),
    );

    // 5. CAPA de la línia del track
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
}
