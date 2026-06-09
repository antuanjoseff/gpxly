import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapBaseLayer extends StatelessWidget {
  final LatLng initialCameraTarget;
  final double initialZoom;
  final bool smartCenterEnabled;
  final bool isProgrammaticMove;
  final bool isFullScreen;
  final void Function(bool) onSmartCenterChanged;
  final void Function(bool) onFullScreenChanged;
  final void Function(MapLibreMapController) onMapCreated;
  final VoidCallback onStyleLoaded;
  final void Function(CameraPosition)? onCameraMove;

  const MapBaseLayer({
    super.key,
    required this.initialCameraTarget,
    required this.initialZoom,
    required this.smartCenterEnabled,
    required this.isProgrammaticMove,
    required this.isFullScreen,
    required this.onSmartCenterChanged,
    required this.onFullScreenChanged,
    required this.onMapCreated,
    required this.onStyleLoaded,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // 🔄 RESTAURACIÓ DEL LISTENER ORIGINAL DE SENDA
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) {
          // Si el moviment de la càmera l'està provocant el codi del GPS,
          // ignorem el toc per evitar falsos positius.
          if (isProgrammaticMove) return;

          // Si el Smart Center està actiu i detectem un toc real, l'apaguem.
          if (smartCenterEnabled) {
            onSmartCenterChanged(false);
          }
        },
        child: MapLibreMap(
          tiltGesturesEnabled: false,
          trackCameraPosition: true,
          compassEnabled: false,
          styleString: "assets/osm_style.json",
          initialCameraPosition: CameraPosition(
            target: initialCameraTarget,
            zoom: initialZoom,
          ),
          onMapLongClick: (point, latlng) => onFullScreenChanged(true),
          onMapClick: (point, latlng) => onFullScreenChanged(false),
          onCameraMove: onCameraMove,
          onCameraIdle: () {
            // Nota: La lògica asíncrona de desar SharedPreferences es delega al controller del pare
          },
          onMapCreated: onMapCreated,
          onStyleLoadedCallback: onStyleLoaded,
        ),
      ),
    );
  }
}
