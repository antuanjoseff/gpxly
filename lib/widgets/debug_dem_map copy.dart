// lib/widgets/debug_dem_map.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  bool get wantKeepAlive => true; // Evita que se destruya el mapa al cambiar de página o hacer scroll

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // Inicializa obligatoriamente el Mixin de persistencia

    // 1. Captura estricta de la posición inicial para el arranque del CameraPosition
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

    // 🛰️ OYENTE GPS REACTIVO: Réplica exacta del comportamiento del mapa principal
    ref.listen(locationProvider, (previous, next) {
      if (!styleInitialized || mapController == null || next == null) return;

      // 🔄 ESTRATEGIA UNIFICADA: Delegamos la actualización al motor de animación original
      mapAnimator?.animateUserPosition(next.position);

      // Acompañamos el movimiento deslizando la cámara de forma suave
      mapController!.animateCamera(CameraUpdate.newLatLng(next.position));
    });

    return SizedBox(
      height: 180,
      child: MapLibreMap(
        tiltGesturesEnabled: false,
        compassEnabled: false,
        styleString: "assets/osm_style.json",
        initialCameraPosition: CameraPosition(
          target: _initialCameraTarget!,
          zoom:
              14.0, // Zoom intermedio para poder apreciar la fluidez del punto azul
        ),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        onMapCreated: (controller) {
          mapController = controller;
        },
        // 🎨 REPLICA EXACTA: Mismo flujo secuencial asíncrono que arranca el motor del mapa principal
        onStyleLoadedCallback: () async {
          print(
            "🎨 [DEBUG MAP] Estil JSON base detectat. Inicialitzant capa de posició...",
          );

          try {
            // Inyectamos la fuente y propiedades de la capa de ubicación compartida por la app
            await setupUserLocationLayer(mapController!);

            // Instanciamos el animador original pasándole el controlador de este mapa
            mapAnimator = MapAnimator(mapController!);

            setState(() {
              styleInitialized =
                  true; // Se abren las compuertas para que el ref.listen envíe datos
            });

            // Forzamos el primer pintado inmediato si ya tenemos coordenadas guardadas
            final currentPos = ref.read(locationProvider);
            if (currentPos != null) {
              mapAnimator?.animateUserPosition(currentPos.position);
            }

            print("✅ [DEBUG MAP] Motor de posicionament unificat i listo.");
          } catch (e) {
            print("⚠️ Error inicialitzant la capa de posició compartida: $e");
          }
        },
      ),
    );
  }
}
