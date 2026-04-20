import 'package:gpxly/notifiers/helpers/closest_result.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/utils/geo_utils.dart';

class TrackGeometryUtils {
  ClosestResult closestPointAndSegment(
    LatLng p,
    List<LatLng> track,
    List<LatLng> lastUserPositions,
  ) {
    double minDist = double.infinity;
    double segmentBearing = 0;
    double userBearing = 0;
    int bestSegmentIndex = 0;
    double bestT = 0;

    LatLng? bestProj;

    for (int i = 0; i < track.length - 1; i++) {
      final a = track[i];
      final b = track[i + 1];

      final abx = b.longitude - a.longitude;
      final aby = b.latitude - a.latitude;

      final apx = p.longitude - a.longitude;
      final apy = p.latitude - a.latitude;

      final ab2 = abx * abx + aby * aby;
      double t = 0;
      if (ab2 > 0) {
        t = (apx * abx + apy * aby) / ab2;
      }

      t = t.clamp(0.0, 1.0);

      final proj = LatLng(a.latitude + aby * t, a.longitude + abx * t);

      final d = distanceBetween(
        p.latitude,
        p.longitude,
        proj.latitude,
        proj.longitude,
      );

      if (d < minDist) {
        minDist = d;
        segmentBearing = bearingBetween(a, b);

        if (lastUserPositions.length >= 2) {
          final prev = lastUserPositions[lastUserPositions.length - 2];
          final curr = lastUserPositions[lastUserPositions.length - 1];
          userBearing = bearingBetween(prev, curr);
        } else {
          userBearing = bearingBetween(a, p);
        }

        bestSegmentIndex = i;
        bestT = t;
        bestProj = proj;
      }
    }

    return ClosestResult(
      distance: minDist,
      bearing: segmentBearing,
      userBearing: userBearing,
      segmentIndex: bestSegmentIndex,
      t: bestT,
      projectedPoint: bestProj!,
    );
  }

  double headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
