// lib/widgets/debug_dem_map.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/utils/map_animator.dart';
import 'package:senda/utils/map_layers.dart';

class DebugDemMap extends ConsumerStatefulWidget {
  const DebugDemMap({super.key});

  @override
  ConsumerState<DebugDemMap> createState() => _DebugDemMapState();
}

class _DebugDemMapState extends ConsumerState<DebugDemMap>
    with AutomaticKeepAliveClientMixin {
  MapLibreMapController? mapController;
  MapAnimator? mapAnimator;

  bool styleInitialized = false;
  LatLng? _initialCameraTarget;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_initialCameraTarget == null) {
      final currentPos = ref.read(locationProvider);
      if (currentPos != null) {
        _initialCameraTarget = currentPos.position;
      } else {
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
    }

    // 🛰️ OYENTE GPS: Animación unificada del punto azul original
    ref.listen(locationProvider, (previous, next) {
      if (!styleInitialized || mapController == null || next == null) return;

      mapAnimator?.animateUserPosition(next.position);
    });

    // 🗺️ OYENTE DEM: Inyección idéntica a tu lógica de trazo de líneas
    ref.listen<List<DemBounds>>(demBoundsProvider, (previous, next) {
      if (styleInitialized && mapController != null) {
        setDemBoundsGeometry(mapController!, next);
      }
    });

    return SizedBox(
      height: 180,
      child: MapLibreMap(
        tiltGesturesEnabled: false,
        compassEnabled: false,
        styleString: "assets/osm_style.json",
        initialCameraPosition: CameraPosition(
          target: _initialCameraTarget!,
          zoom: 10.0,
        ),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        onMapCreated: (controller) {
          mapController = controller;
        },
        // 🎨 FIRMA OFICIAL: Corregimos el orden de parámetros de addLayer basándonos en el repositorio
        onStyleLoadedCallback: () async {
          print(
            "🎨 [DEBUG MAP] Inicialitzant capes segons el repositori oficial...",
          );
          try {
            // 1. Añadimos primero la fuente GeoJSON para los polígonos DEM
            await mapController!.addSource(
              "dem_bounds_source",
              const GeojsonSourceProperties(
                data: {"type": "FeatureCollection", "features": []},
              ),
            );

            // 2. Capa de relleno naranja (Capa Base)
            // Estructura oficial: addLayer(sourceId, layerId, properties)
            await mapController!.addLayer(
              "dem_bounds_source", // sourceId
              "dem_bounds_fill_layer", // layerId
              const FillLayerProperties(
                fillColor: "#FF9800",
                fillOpacity: 0.25,
              ),
            );

            // 3. Capa de línea discontinua de contorno
            await mapController!.addLayer(
              "dem_bounds_source", // sourceId
              "dem_bounds_layer", // layerId
              const LineLayerProperties(
                lineColor: "#FF9800",
                lineWidth: 3.0,
                lineDasharray: [4.0, 2.0],
              ),
            );

            // 4. Cargamos el punto azul usando los inicializadores compartidos de tu app
            await setupUserLocationLayer(mapController!);
            mapAnimator = MapAnimator(mapController!);

            await Future.delayed(const Duration(milliseconds: 150));
            if (!mounted) return;

            setState(() {
              styleInitialized = true;
            });

            // Volcado inicial en caliente de los datos existentes en Riverpod
            setDemBoundsGeometry(mapController!, ref.read(demBoundsProvider));

            final currentPos = ref.read(locationProvider);
            if (currentPos != null) {
              mapAnimator?.animateUserPosition(currentPos.position);
            }

            print("✅ [DEBUG MAP] Inicialitzat correctament.");
          } catch (e) {
            print("⚠️ Error en onStyleLoaded del mapa de debug: $e");
          }
        },
      ),
    );
  }
}
