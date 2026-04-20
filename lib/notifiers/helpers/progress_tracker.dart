import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/utils/geo_utils.dart';

class ProgressTracker {
  double distanceProgressOnTrack = 0.0;
  LatLng? lastProjectedPoint;

  void updateProgress(LatLng proj) {
    if (lastProjectedPoint != null) {
      final step = distanceBetween(
        lastProjectedPoint!.latitude,
        lastProjectedPoint!.longitude,
        proj.latitude,
        proj.longitude,
      );
      if (step > 0 && step < 50) {
        distanceProgressOnTrack += step;
      }
    }
    lastProjectedPoint = proj;
  }
}
