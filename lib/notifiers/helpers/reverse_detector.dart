import 'package:senda/notifiers/helpers/closest_result.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/utils/geo_utils.dart';

class ReverseDetector {
  bool isReverseDirection(ClosestResult c, List<LatLng> pts) {
    // --- 1. Necessitem un mínim de punts (nivell 3) ---
    if (pts.length < TrackThresholds.minPositionsLevel3) return false;

    // --- 2. Definim la finestra de càlcul ---
    const int N = TrackThresholds.minPositionsLevel3;
    final window = pts.sublist(pts.length - N);

    final LatLng first = window.first;
    final LatLng last = window.last;

    // --- 3. Distància neta recorreguda ---
    final netDistance = distanceBetween(
      first.latitude,
      first.longitude,
      last.latitude,
      last.longitude,
    );

    // Si no hi ha moviment real → no hi ha reverse
    if (netDistance < TrackThresholds.reverseMinDistance) return false;

    // --- 4. Bearing mitjà de moviment ---
    final movementBearing = _averageBearing(window);

    // --- 5. Diferència amb el bearing del track ---
    final diff = _headingDifference(c.bearing, movementBearing);

    // --- 6. Condició final ---
    return diff > 140;
  }

  bool isReverseSegmentProgression(List<int> segmentIndices) {
    final n = TrackThresholds.reverseSegmentWindow;
    if (segmentIndices.length < n) return false;

    final window = segmentIndices.sublist(segmentIndices.length - n);

    int negativeSteps = 0;
    int deltaSum = 0;

    for (int i = 1; i < window.length; i++) {
      final delta = window[i] - window[i - 1];
      deltaSum += delta;
      if (delta < 0) negativeSteps++;
    }

    return negativeSteps >= TrackThresholds.reverseMinNegativeSteps &&
        deltaSum <= -TrackThresholds.reverseMinDeltaSum;
  }

  // ------------------------------------------------------------
  // Bearing mitjà entre punts consecutius
  // ------------------------------------------------------------
  double _averageBearing(List<LatLng> pts) {
    double sum = 0;
    int count = 0;

    for (int i = 1; i < pts.length; i++) {
      sum += bearingBetween(pts[i - 1], pts[i]);
      count++;
    }

    return sum / count;
  }

  // ------------------------------------------------------------
  // Diferència de heading normalitzada
  // ------------------------------------------------------------
  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
