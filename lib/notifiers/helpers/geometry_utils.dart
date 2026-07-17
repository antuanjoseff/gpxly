import 'package:senda/notifiers/helpers/closest_result.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/utils/geo_utils.dart';

class TrackGeometryUtils {
  ClosestResult closestPointAndSegment(
    LatLng p,
    List<LatLng> track,
    List<LatLng> lastUserPositions, {
    int? preferredSegmentIndex,
    int segmentSearchWindow = 0,
  }) {
    double minDist = double.infinity;
    double segmentBearing = 0;
    double userBearing = 0;
    int bestSegmentIndex = 0;
    double bestT = 0;

    LatLng? bestProj;

    final int maxSegment = track.length - 2;
    int startSegment = 0;
    int endSegment = maxSegment;

    if (preferredSegmentIndex != null &&
        segmentSearchWindow > 0 &&
        maxSegment >= 0) {
      final clampedPreferred = preferredSegmentIndex.clamp(0, maxSegment);
      startSegment = (clampedPreferred - segmentSearchWindow).clamp(
        0,
        maxSegment,
      );
      endSegment = (clampedPreferred + segmentSearchWindow).clamp(
        0,
        maxSegment,
      );
    }

    for (int i = startSegment; i <= endSegment; i++) {
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

      // =========================================================================
      // 🛠️ FILTRE D'ANTI-SALT PER A TRAJECTÒRIES PROBABILÍSTIQUES COHERENTS
      // =========================================================================
      double virtualDistance = d;

      if (preferredSegmentIndex != null) {
        final int indexDifference = (i - preferredSegmentIndex).abs();

        // Si el segment avaluat està lluny de l'anterior (ex: saltar d'anada a tornada),
        // hi afegim una penalització virtual de 15 metres. El GPS només farà el salt
        // si l'usuari realment s'ha mogut cap al nou camí de manera sostinguda.
        if (indexDifference > 8) {
          virtualDistance += 15.0;
        }
      }
      // =========================================================================

      if (virtualDistance < minDist) {
        minDist = virtualDistance;
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

    // Retornem la distància física real (sense penalització) per no enganyar els automatismes d'Off-Track
    final double realDistance = distanceBetween(
      p.latitude,
      p.longitude,
      bestProj!.latitude,
      bestProj.longitude,
    );

    return ClosestResult(
      distance: realDistance,
      bearing: segmentBearing,
      userBearing: userBearing,
      segmentIndex: bestSegmentIndex,
      t: bestT,
      projectedPoint: bestProj,
    );
  }

  double headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
