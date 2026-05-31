// lib/utils/debug_map_animator.dart
import 'dart:async';

import 'package:maplibre_gl/maplibre_gl.dart';

class DebugMapAnimator {
  final MapLibreMapController controller;
  LatLng? _lastUserPos;
  Timer? _displacementTimer;

  DebugMapAnimator(this.controller);

  void animateUserPosition(LatLng? newPos) {
    if (newPos == null) return;

    // Si es la primera posición, la pintamos de golpe sin animar
    if (_lastUserPos == null) {
      _setUserDotGeometry(newPos.latitude, newPos.longitude);
      _lastUserPos = newPos;
      return;
    }

    final from = _lastUserPos!;
    final to = newPos;

    const totalSteps = 15;
    int currentStep = 0;

    // Cancelamos cualquier animación en curso para evitar hilos zombis
    _displacementTimer?.cancel();

    // Bucle cinemático síncrono controlado idéntico al del mapa principal
    _displacementTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      currentStep++;
      final double t = currentStep / totalSteps;

      final double animatedLat =
          from.latitude + (to.latitude - from.latitude) * t;
      final double animatedLon =
          from.longitude + (to.longitude - from.longitude) * t;

      _setUserDotGeometry(animatedLat, animatedLon);
      _lastUserPos = LatLng(animatedLat, animatedLon);

      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  // Modifica la capa nativa inyectando el punto GeoJSON plano
  void _setUserDotGeometry(double lat, double lon) {
    final Map<String, dynamic> pointPayload = {
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
    };
    controller.setGeoJsonSource("debug_user_dot_source", pointPayload);
  }

  void dispose() {
    _displacementTimer?.cancel();
  }
}
