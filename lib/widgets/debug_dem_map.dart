// lib/widgets/debug_dem_map.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';

class DebugDemMap extends ConsumerStatefulWidget {
  const DebugDemMap({super.key});

  @override
  ConsumerState<DebugDemMap> createState() => _DebugDemMapState();
}

class _DebugDemMapState extends ConsumerState<DebugDemMap>
    with AutomaticKeepAliveClientMixin {
  MapLibreMapController? _miniMapController;
  bool _styleLoaded = false;

  @override
  bool get wantKeepAlive => true; // Evita que se destruya el mapa al hacer scroll

  @override
  Widget build(BuildContext context) {
    super.build(context); // Inicializa el KeepAlive

    final userPos = ref.watch(locationProvider);

    // Escuchamos la pizarra reactiva de Riverpod
    ref.listen<List<DemBounds>>(demBoundsProvider, (previous, next) {
      if (_styleLoaded && _miniMapController != null) {
        _updateDemLayers(next);
      }
    });

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

    return MapLibreMap(
      tiltGesturesEnabled: false,
      compassEnabled: false,
      styleString: "assets/osm_style.json",
      initialCameraPosition: CameraPosition(
        target: userPos.position,
        zoom:
            10.0, // Alejado a 10.0 para poder contemplar el rectángulo de 15km
      ),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onMapCreated: (controller) => _miniMapController = controller,
      // 🔥 CORREGIDO: Declaramos asíncrono el callback para esperar a las capas
      onStyleLoadedCallback: () async {
        if (!mounted) return;
        setState(() {
          _styleLoaded = true;
        });

        // 🔥 CLAVE 1: Forzamos el await para que no se inyecten datos antes de crear las capas
        await _setupDebugLayers();
      },
    );
  }

  Future<void> _setupDebugLayers() async {
    if (_miniMapController == null || !mounted) return;

    try {
      // 1. Añadimos la fuente GeoJSON nativa de forma segura
      await _miniMapController!.addSource(
        "dem_bounds_source",
        const GeojsonSourceProperties(
          data: {"type": "FeatureCollection", "features": []},
        ),
      );

      // 2. Capa de relleno poligonal (Pintada primero para que quede abajo)
      await _miniMapController!.addLayer(
        "dem_bounds_fill_layer",
        "building", // 🚀 TRUCO DE CONTRASTE: La colocamos justo encima de los edificios
        const FillLayerProperties(
          fillColor: "#FF9800",
          fillOpacity: 0.30, // Opacidad sutil y elegante del 30%
        ),
      );

      // 3. Capa de la línea exterior discontinua (Pintada encima del relleno)
      await _miniMapController!.addLayer(
        "dem_bounds_layer",
        "dem_bounds_fill_layer", // 🚀 CLAVE: Se apoya de forma segura sobre el ID del relleno
        const LineLayerProperties(
          lineColor: "#FF9800",
          lineWidth: 3.5,
          lineDasharray: [4.0, 2.0], // 4px trazo, 2px vacío
        ),
      );

      // Retardo de seguridad para que la GPU procese los IDs sin estrés asíncrono
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _updateDemLayers(ref.read(demBoundsProvider));
        }
      });
    } catch (e) {
      print("⚠️ Error creant les capes visuals DEM de debug: $e");
    }
  }

  void _updateDemLayers(List<DemBounds> cells) {
    if (_miniMapController == null || !_styleLoaded || !mounted) return;

    final List<Map<String, dynamic>> features = [];

    for (final cell in cells) {
      features.add({
        "type": "Feature",
        "id": "cell_${cell.minLon.toStringAsFixed(3)}",
        "properties": {"path": "dem_cell"},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              // 🔄 CLAVE 3: SENTIDO ANTIHORARIO (CCW) ESTRICTO PARA LA GPU NATIVA
              [cell.minLon, cell.minLat], // 1. Abajo-Izquierda
              [cell.maxLon, cell.minLat], // 2. Abajo-Derecha
              [cell.maxLon, cell.maxLat], // 3. Arriba-Derecha
              [cell.minLon, cell.maxLat], // 4. Arriba-Izquierda
              [cell.minLon, cell.minLat], // 5. Cierre geométrico
            ],
          ],
        },
      });
    }

    final Map<String, dynamic> geoJsonPayload = {
      "type": "FeatureCollection",
      "features": features,
    };

    print("🌍 [AUDITORIA GEOJSON MAPA] Contingut de l'estructura:");
    print(geoJsonPayload.toString());

    if (!mounted || _miniMapController == null) return;

    // Inyectamos los datos estructurados planos de Dart
    _miniMapController!.setGeoJsonSource("dem_bounds_source", geoJsonPayload);

    // 🔥 CLAVE 4: Sacudida invisible de cámara para despertar el refresco de píxeles nativo
    final currentCamera = _miniMapController!.cameraPosition;
    if (currentCamera != null) {
      _miniMapController!.moveCamera(
        CameraUpdate.newLatLng(
          LatLng(
            currentCamera.target.latitude + 0.000001,
            currentCamera.target.longitude,
          ),
        ),
      );
    }
  }
}
