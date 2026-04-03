import 'dart:async';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Anima el darrer segment del track amb interpolació suau.
///
/// [lat], [lon] → nova posició real
/// [allCoordinates] → track complet
/// [controller] → MapLibre controller
/// [userMovedMap] → si l’usuari ha mogut el mapa, no recentrem
/// [setLastPosition] → callback per actualitzar _lastPosition al MapScreen
/// [setTimer] → callback per guardar el Timer a MapScreen
/// [currentLastPosition] → valor actual de _lastPosition
/// [currentTimer] → valor actual de _animationTimer
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
}) {
  final newPos = LatLng(lat, lon);

  // Si la posició no ha canviat, no animem
  if (currentLastPosition != null &&
      currentLastPosition.latitude == newPos.latitude &&
      currentLastPosition.longitude == newPos.longitude) {
    return;
  }

  // Si ja hi ha una animació en marxa, no la reiniciem
  if (currentTimer != null && currentTimer.isActive) return;

  // 🔵 CAS ESPECIAL: només hi ha un punt → dibuix immediat
  if (allCoordinates.length < 2) {
    setLastPosition(newPos);

    // Punt blau
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

    // Línia (amb 1 punt no es veu, però és correcte)
    controller.setGeoJsonSource("track_line", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": allCoordinates},
        },
      ],
    });

    return;
  }

  // 🔴 A partir d’aquí → animació
  final fullTrack = List<List<double>>.from(allCoordinates);
  final penultimate = fullTrack[fullTrack.length - 2];
  final startLat = penultimate[1];
  final startLon = penultimate[0];

  int currentStep = 0;

  final timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
    const steps = 10;

    currentStep++;

    final deltaLat = (lat - startLat) / steps;
    final deltaLon = (lon - startLon) / steps;

    final animatedLat = startLat + deltaLat * currentStep;
    final animatedLon = startLon + deltaLon * currentStep;

    // 🔵 Actualitzar punt blau
    controller.setGeoJsonSource("user_location", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [animatedLon, animatedLat],
          },
        },
      ],
    });

    // 🔴 Actualitzar línia amb el punt interpolat
    final animatedCoordinates = [
      ...fullTrack.sublist(0, fullTrack.length - 1),
      [animatedLon, animatedLat],
    ];

    controller.setGeoJsonSource("track_line", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": animatedCoordinates,
          },
        },
      ],
    });

    // Final de l’animació
    if (currentStep >= steps) {
      t.cancel();
      setLastPosition(newPos);

      if (!userMovedMap) {
        print(">>> RECENTERING FROM animateLastSegment()");
        controller.animateCamera(CameraUpdate.newLatLng(newPos));
      }

      setTimer(null);
    }
  });

  setTimer(timer);
}
