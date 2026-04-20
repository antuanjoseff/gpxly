import 'package:gpxly/notifiers/helpers/closest_result.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/utils/geo_utils.dart';

class ReverseDetector {
  bool isReverseDirection(ClosestResult c, List<LatLng> lastUserPositions) {
    if (lastUserPositions.length < 2) return false;

    final prev = lastUserPositions[lastUserPositions.length - 2];
    final curr = lastUserPositions[lastUserPositions.length - 1];

    final movement = distanceBetween(
      prev.latitude,
      prev.longitude,
      curr.latitude,
      curr.longitude,
    );

    if (movement < 3) return false;

    final movementBearing = bearingBetween(prev, curr);
    final diff = _headingDifference(c.bearing, movementBearing);
    return diff > 135;
  }

  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
