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
  final VoidCallback? onCameraIdle; // 🚀 1. NUEVO CALLBACK EXPUESTO

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
    this.onCameraIdle, // 🚀 2. AÑADIDO AL CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) {
          if (isProgrammaticMove) return;
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
          // 🚀 3. CONECTAMOS EL MAPA NATIVO CON TU NUEVA PROPIEDAD
          onCameraIdle: onCameraIdle,
          onMapCreated: onMapCreated,
          onStyleLoadedCallback: onStyleLoaded,
        ),
      ),
    );
  }
}
