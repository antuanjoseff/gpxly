import 'dart:async';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Anima el darrer segment del track amb interpolació suau i manté el Smart Center.
void animateLastSegment({
  required double lat,
  required double lon,
  required List<List<double>> allCoordinates,
  required MapLibreMapController controller,
  required bool userMovedMap,
  required LatLng? currentLastPosition,
  required Timer? currentTimer,
  required void Function(LatLng) setLastPosition,
  required void Function(Timer?) setTimer,
  required void Function(bool) onAnimate,
  void Function(double lon, double lat)? overrideDrawPoint,
  void Function(List<List<double>> coords)? overrideDrawLine,
  bool drawSegment = true,
}) {
  final newPos = LatLng(lat, lon);

  // 1. Evitar ejecuciones duplicadas o innecesarias
  if (currentLastPosition != null &&
      currentLastPosition.latitude == newPos.latitude &&
      currentLastPosition.longitude == newPos.longitude) {
    return;
  }
  if (currentTimer != null && currentTimer.isActive) return;

  // 2. Punto de inicio de la animación (desde donde está el punto azul ahora)
  final double startLat = currentLastPosition?.latitude ?? lat;
  final double startLon = currentLastPosition?.longitude ?? lon;

  // 3. Caso inicial: Pocos puntos
  if (allCoordinates.length < 2) {
    setLastPosition(newPos);
    _updateUserLocationSource(controller, lon, lat, overrideDrawPoint);
    if (drawSegment) {
      _updateTrackLineSource(controller, allCoordinates, overrideDrawLine);
    }
    return;
  }

  // 4. Preparar la animación por pasos
  int currentStep = 0;
  const int steps = 10;

  // Bloqueamos el "semáforo" (isAnimatingSegment e isProgrammaticMove = true)
  onAnimate(true);

  final timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
    currentStep++;

    final double animatedLat =
        startLat + (lat - startLat) * (currentStep / steps);
    final double animatedLon =
        startLon + (lon - startLon) * (currentStep / steps);

    // A) Mover Punto Azul
    _updateUserLocationSource(
      controller,
      animatedLon,
      animatedLat,
      overrideDrawPoint,
    );

    // B) Estirar Línea
    if (drawSegment) {
      final animatedCoordinates = [
        ...allCoordinates.sublist(0, allCoordinates.length - 1),
        [animatedLon, animatedLat],
      ];
      _updateTrackLineSource(controller, animatedCoordinates, overrideDrawLine);
    }

    // 5. Finalizar animación y gestionar Smart Center
    if (currentStep >= steps) {
      t.cancel();
      setLastPosition(newPos);
      setTimer(null);

      // Si el usuario NO ha movido el mapa manualmente, centramos la cámara
      if (!userMovedMap) {
        controller.animateCamera(CameraUpdate.newLatLng(newPos)).then((_) {
          // ESPERAMOS a que la cámara termine para no romper el Smart Center
          Future.delayed(const Duration(milliseconds: 150), () {
            onAnimate(false); // Liberamos los flags
          });
        });
      } else {
        // Si el usuario movió el mapa, no movemos cámara y liberamos ya
        onAnimate(false);
      }
    }
  });

  setTimer(timer);
}

// --- HELPERS ---

void _updateUserLocationSource(
  MapLibreMapController controller,
  double lon,
  double lat,
  Function? override,
) {
  if (override != null) {
    override(lon, lat);
  } else {
    controller.setGeoJsonSource("user_location", {
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
  }
}

void _updateTrackLineSource(
  MapLibreMapController controller,
  List<List<double>> coords,
  Function? override,
) {
  if (override != null) {
    override(coords);
  } else {
    controller.setGeoJsonSource("track_line", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coords},
        },
      ],
    });
  }
}
