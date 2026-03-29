import '../models/track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../services/gps_service.dart';
import 'package:geolocator/geolocator.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  bool recording = false;
  MapLibreMapController? mapController;
  // String mapStyle = "https://demotiles.maplibre.org/style.json";
  String mapStyle = "assets/osm_style.json";

  @override
  Widget build(BuildContext context) {
    // Escoltem canvis del trackProvider de manera segura
    ref.listen<Track>(trackProvider, (previous, next) {
      if (recording && mounted) {
        _updateMap(next);
      }
    });

    final track = ref.watch(trackProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Track GPS")),
      body: Column(
        children: [
          Expanded(
            child: MapLibreMap(
              styleString: mapStyle,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 14,
              ),
              onMapCreated: (controller) async {
                mapController = controller;

                // 1. Demanem permís de localització
                final permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  return;
                }

                // 2. Obtenim posició actual
                final pos = await Geolocator.getCurrentPosition();

                // 3. Centrem el mapa
                controller.animateCamera(
                  CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
                );
              },
            ),
          ),

          // Botons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // INICIAR
              ElevatedButton(
                onPressed: recording
                    ? null
                    : () async {
                        setState(() => recording = true);
                        ref.read(trackProvider.notifier).reset();
                        await ref.read(trackProvider.notifier).startRecording();
                      },
                child: const Text("Iniciar"),
              ),

              // PARAR
              ElevatedButton(
                onPressed: recording
                    ? () async {
                        setState(() => recording = false);
                        await ref.read(trackProvider.notifier).stopRecording();
                      }
                    : null,
                child: const Text("Parar"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actualitza la línia del track al mapa
  void _updateMap(Track track) {
    if (!mounted || mapController == null || track.coordinates.isEmpty) return;

    final latLngList = track.coordinates
        .map((c) => LatLng(c[0] as double, c[1] as double))
        .toList();

    mapController!.clearLines();

    mapController!.addLine(
      LineOptions(
        geometry: latLngList,
        lineColor: "#FF0000",
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ),
    );

    mapController!.animateCamera(CameraUpdate.newLatLng(latLngList.last));
  }
}
