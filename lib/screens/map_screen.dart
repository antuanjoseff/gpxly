import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../services/gps_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? mapController;
  bool styleInitialized = false;

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);

    // Quan arriben noves coordenades → actualitzar punt + centrar mapa
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;
      if (next.coordinates.isEmpty) return;

      final last = next.coordinates.last;
      final lon = last[0];
      final lat = last[1];

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

      // Centrar mapa
      mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon)));
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

            onMapCreated: (controller) {
              mapController = controller;
            },

            // AQUEST és el callback que SÍ funciona a la 0.25.0
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
                final notifier = ref.read(trackProvider.notifier);

                if (!track.recording) {
                  // 0. Comprovar permís
                  LocationPermission permission =
                      await Geolocator.checkPermission();

                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }

                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cal donar permís de localització"),
                      ),
                    );
                    return;
                  }

                  // 1. Obtenir posició actual
                  final pos = await Geolocator.getCurrentPosition();
                  // AFEGIR PRIMERA COORDENADA AL TRACK
                  ref
                      .read(trackProvider.notifier)
                      .addCoordinate(pos.latitude, pos.longitude);

                  // 2. Centrar el mapa
                  if (mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(pos.latitude, pos.longitude),
                      ),
                    );
                  }

                  // 3. Iniciar gravació
                  notifier.startRecording();
                } else {
                  notifier.stopRecording();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Configura la font i capa per mostrar el punt de l’usuari
  Future<void> _setupUserLocationLayer() async {
    if (mapController == null) return;

    // 1. Crear icona en memòria
    final Uint8List blueDot = await _createBlueDot();
    await mapController!.addImage("user_icon", blueDot);

    // 2. Crear SOURCE buida
    await mapController!.addSource(
      "user_location",
      GeojsonSourceProperties(
        data: {"type": "FeatureCollection", "features": []},
      ),
    );

    // 3. Crear CAPA amb la icona
    await mapController!.addLayer(
      "user_location",
      "user_location_layer",
      const SymbolLayerProperties(iconImage: "user_icon", iconSize: 1.0),
    );

    await mapController!.setGeoJsonSource("user_location", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [2.82, 41.98], // Girona
          },
        },
      ],
    });
  }

  Future<Uint8List> _createBlueDot() async {
    const int size = 64;
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.blue;

    // Cercle blau
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
