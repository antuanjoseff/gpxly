import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
  }

  MapLibreMapController? mapController;

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    ref.listen(trackProvider, (previous, next) {
      if (mapController == null) return;

      // Si hi ha almenys un punt, centrem el mapa
      if (next.coordinates.isNotEmpty) {
        final last = next.coordinates.last;
        final lat = last[0];
        final lon = last[1];

        mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon)));
      }
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
                    // No tenim permís → no fem res
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cal donar permís de localització"),
                      ),
                    );
                    return;
                  }

                  // 1. Obtenir posició actual (ara sí, segur)
                  final pos = await Geolocator.getCurrentPosition();

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
}
