// lib/widgets/debug_dem_map.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/services/cog_service.dart';

class DebugDemMap extends ConsumerStatefulWidget {
  const DebugDemMap({super.key});

  @override
  ConsumerState<DebugDemMap> createState() => _DebugDemMapState();
}

class _DebugDemMapState extends ConsumerState<DebugDemMap> {
  MapLibreMapController? _miniMapController;
  bool _styleLoaded = false;

  @override
  Widget build(BuildContext context) {
    final userPos = ref.watch(locationProvider);

    // Si el GPS es mou i l'estil ja s'havia carregat, actualitzem geometries de fons
    if (_styleLoaded && _miniMapController != null) {
      _miniMapController!.onStyleLoadedCallback?.call();
    }

    if (userPos == null) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "Esperant senyal GPS per al Mini-Mapa...",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200, // Pujat una mica a 200px per a millor usabilitat de gestos
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MapLibreMap(
          tiltGesturesEnabled: false,
          compassEnabled: false,
          styleString: "assets/osm_style.json",
          initialCameraPosition: CameraPosition(
            target: userPos.position,
            zoom: 11.5,
          ),

          // ─────────────────────────────────────────────────────────────
          // 🔥 CLAU 1: DESBLOQUEJAR PAN, ZOOM IN I ZOOM OUT DINS DEL LISTVIEW
          // ─────────────────────────────────────────────────────────────
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () =>
                  EagerGestureRecognizer(), // Força al mapa a agafar el control dels dits a l'acte
            ),
          },

          onMapCreated: (controller) => _miniMapController = controller,
          onStyleLoadedCallback: () {
            // El bloc s'executa de forma segura en un micro-retall per evitar col·lisions d'estat
            if (!mounted) return;
            setState(() {
              _styleLoaded = true;
            });
            _setupDebugLayers();
          },
        ),
      ),
    );
  }

  void _setupDebugLayers() async {
    if (_miniMapController == null) return;

    try {
      // 1. Creem la font GeoJSON en memòria nativa
      await _miniMapController!.addSource(
        "dem_bounds_source",
        const GeojsonSourceProperties(
          data: {"type": "FeatureCollection", "features": []},
        ),
      );

      // 2. Capa de la línia exterior discontínua (Taronja de depuració)
      await _miniMapController!.addLayer(
        "dem_bounds_layer",
        "", // Per damunt de tot
        const LineLayerProperties(
          lineColor: "#FF9800",
          lineWidth: 2.5,
          lineDasharray: [3.0, 3.0], // 3px línia, 3px buit
        ),
      );

      // 3. Capa de farcit poligonal translúcid
      await _miniMapController!.addLayer(
        "dem_bounds_fill_layer",
        "dem_bounds_layer", // Just per sota de la seva pròpia línia de contorn
        const FillLayerProperties(fillColor: "#FF9800", fillOpacity: 0.15),
      );

      // Llançem la primera càrrega dinàmica de cels descarregats
      _updateDemLayers();
    } catch (e) {
      print("⚠️ Error creant les capes visuals DEM de debug: $e");
    }
  }

  void _updateDemLayers() {
    if (_miniMapController == null || !_styleLoaded) return;

    // Llegim la llista real de mapes en memòria cau des del teu CogService Singleton
    final activeMaps = CogService().activeCacheMaps;
    final List<Map<String, dynamic>> features = [];

    print(
      "📊 [DEBUG MAPA] Dibuixant rectangles DEM actius a la RAM. Total: ${activeMaps.length}",
    );

    for (final map in activeMaps) {
      features.add({
        "type": "Feature",
        "properties": {"path": map.path},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [map.minLon, map.minLat], // 1. Baix-Esquerra
              [map.maxLon, map.minLat], // 2. Baix-Dreta
              [map.maxLon, map.maxLat], // 3. Dalt-Dreta
              [map.minLon, map.maxLat], // 4. Dalt-Esquerra
              [map.minLon, map.minLat], // 5. Tancament geomètric
            ],
          ],
        },
      });
    }

    _miniMapController!.setGeoJsonSource("dem_bounds_source", {
      "type": "FeatureCollection",
      "features": features,
    });
  }
}
