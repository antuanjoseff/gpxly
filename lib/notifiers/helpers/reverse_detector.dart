import 'package:flutter/material.dart';
import 'package:senda/notifiers/helpers/closest_result.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/utils/geo_utils.dart';

class ReverseDetector {
  bool isReverseDirection(ClosestResult c, List<LatLng> lastUserPositions) {
    // 1. Necessitem un historial mínim per ser fiables (p. ex. 6 punts)
    if (lastUserPositions.length < 6) return false;

    // 2. Agafem un punt de referència més enrere (per exemple, fa 5 posicions)
    final oldPos = lastUserPositions[lastUserPositions.length - 6];
    final currPos = lastUserPositions.last;

    // 3. Calculem la distància neta recorreguda en aquest interval
    final netDistance = distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      currPos.latitude,
      currPos.longitude,
    );

    // 🔥 FILTRE CLAU: Només comprovem si hem recorregut una distància neta raonable.
    // Això evita que salts petits del GPS mentre estàs quiet disparin l'alerta.
    if (netDistance < TrackThresholds.reverseMinDistance) return false;

    // 4. Calculem el rumb real de la trajectòria (no d'un sol salt)
    final movementBearing = bearingBetween(oldPos, currPos);

    // 5. Comparem amb el rumb del track
    final diff = _headingDifference(c.bearing, movementBearing);

    // Si la trajectòria real consolidada és oposada (>140º), és un positiu real
    return diff > 140;
  }

  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
