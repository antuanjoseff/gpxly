// lib/services/gpx_import_service.dart
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpx/gpx.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/utils/calculations.dart';
import 'package:senda/utils/geo_utils.dart';

DateTime truncateSeconds(DateTime t) {
  return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
}

class GpxImportService {
  static Future<void> importGpx(WidgetRef ref, String xmlString) async {
    final gpx = GpxReader().fromString(xmlString);

    if (gpx.trks.isEmpty || gpx.trks.first.trksegs.isEmpty) return;

    final gpxPoints = gpx.trks.first.trksegs.first.trkpts;
    if (gpxPoints.isEmpty) return;

    final loadedPoints = <UserPosition>[];
    double accumulatedDistance = 0.0;

    double minLat = 90.0, maxLat = -90.0;
    double minLon = 180.0, maxLon = -180.0;
    double minEle = double.infinity, maxEle = -double.infinity;

    double maxSpeed = 0.0;

    double? lastLat;
    double? lastLon;
    DateTime? lastTime;

    for (int i = 0; i < gpxPoints.length; i++) {
      final p = gpxPoints[i];
      if (p.lat == null || p.lon == null || p.time == null) continue;

      final currentLat = p.lat!;
      final currentLon = p.lon!;
      final currentAlt = p.ele ?? 0.0;
      final normalizedTime = truncateSeconds(p.time!.toLocal());

      if (currentLat < minLat) minLat = currentLat;
      if (currentLat > maxLat) maxLat = currentLat;
      if (currentLon < minLon) minLon = currentLon;
      if (currentLon > maxLon) maxLon = currentLon;
      if (currentAlt < minEle) minEle = currentAlt;
      if (currentAlt > maxEle) maxEle = currentAlt;

      double segmentSpeed = 0.0;

      if (i > 0 && lastLat != null && lastLon != null && lastTime != null) {
        final double distanceDelta = haversineDistance(
          lastLat,
          lastLon,
          currentLat,
          currentLon,
        );
        accumulatedDistance += distanceDelta;

        final int timeDeltaSeconds = normalizedTime
            .difference(lastTime)
            .inSeconds;

        if (timeDeltaSeconds > 0) {
          segmentSpeed = distanceDelta / timeDeltaSeconds;
          if (segmentSpeed > maxSpeed) {
            maxSpeed = segmentSpeed;
          }
        }
      }

      lastLat = currentLat;
      lastLon = currentLon;
      lastTime = normalizedTime;

      loadedPoints.add(
        UserPosition(
          position: LatLng(currentLat, currentLon),
          altitude: currentAlt,
          isHgtFixed: false,
          timestamp: normalizedTime,
          accuracy: 0.0,
          vAccuracy: 0.0,
          speed: segmentSpeed,
          heading: 0.0,
          satellites: p.sat ?? 0,
          distanceAtPoint: accumulatedDistance,
        ),
      );
    }

    if (loadedPoints.isEmpty) return;

    // 1) Simplificació Douglas–Peucker
    final simplifiedPoints = simplifyTrack(loadedPoints, 4.0);
    if (simplifiedPoints.isEmpty) return;

    // 2) Recalcular distància acumulada sobre el track simplificat
    double acc = 0.0;
    for (int i = 0; i < simplifiedPoints.length; i++) {
      if (i > 0) {
        acc += haversineDistance(
          simplifiedPoints[i - 1].position.latitude,
          simplifiedPoints[i - 1].position.longitude,
          simplifiedPoints[i].position.latitude,
          simplifiedPoints[i].position.longitude,
        );
      }
      simplifiedPoints[i] = simplifiedPoints[i].copyWith(distanceAtPoint: acc);
    }

    // 3) Bounds recalculats sobre el track simplificat
    minLat = simplifiedPoints
        .map((p) => p.position.latitude)
        .reduce((a, b) => a < b ? a : b);
    maxLat = simplifiedPoints
        .map((p) => p.position.latitude)
        .reduce((a, b) => a > b ? a : b);
    minLon = simplifiedPoints
        .map((p) => p.position.longitude)
        .reduce((a, b) => a < b ? a : b);
    maxLon = simplifiedPoints
        .map((p) => p.position.longitude)
        .reduce((a, b) => a > b ? a : b);
    minEle = simplifiedPoints
        .map((p) => p.altitude)
        .reduce((a, b) => a < b ? a : b);
    maxEle = simplifiedPoints
        .map((p) => p.altitude)
        .reduce((a, b) => a > b ? a : b);

    print(
      ">>> INDESTRUCTIBLE GPX BOUNDS: "
      "minLat=$minLat, maxLat=$maxLat, "
      "minLon=$minLon, maxLon=$maxLon",
    );

    Duration totalDuration = Duration.zero;
    if (simplifiedPoints.length > 1) {
      totalDuration = simplifiedPoints.last.timestamp.difference(
        simplifiedPoints.first.timestamp,
      );
    }

    double averageSpeed = 0.0;
    if (totalDuration.inSeconds > 0) {
      averageSpeed = acc / totalDuration.inSeconds;
    }

    final simplifiedAlts = simplifiedPoints
        .map((p) => p.altitude)
        .toList(growable: false);
    final ascent = computeAscent(simplifiedAlts);
    final descent = computeDescent(simplifiedAlts);

    final importedTrack = Track(
      points: simplifiedPoints,
      recordingState: RecordingState.idle,
      stats: TrackStats(
        duration: totalDuration,
        stoppedDuration: Duration.zero,
        distance: acc,
        ascent: ascent,
        descent: descent,
        maxElevation: maxEle == -double.infinity ? 0.0 : maxEle,
        minElevation: minEle == double.infinity ? 0.0 : minEle,
        averageSpeed: averageSpeed,
        maxSpeed: maxSpeed,
        minLat: minLat,
        maxLat: maxLat,
        minLon: minLon,
        maxLon: maxLon,
      ),
    );

    ref.read(importedTrackProvider.notifier).setTrack(importedTrack);

    // 4) Waypoints sobre el track simplificat
    int findClosestTrackIndex(double wpLat, double wpLon) {
      double minDist = double.infinity;
      int minIndex = 0;

      for (int i = 0; i < simplifiedPoints.length; i++) {
        final pos = simplifiedPoints[i].position;
        final d = haversineDistance(wpLat, wpLon, pos.latitude, pos.longitude);

        if (d < minDist) {
          minDist = d;
          minIndex = i;
        }
      }
      return minIndex;
    }

    final importedWaypoints = <Waypoint>[];

    for (final w in gpx.wpts) {
      if (w.lat == null || w.lon == null) continue;

      final closestIndex = findClosestTrackIndex(w.lat!, w.lon!);
      final targetPoint = simplifiedPoints[closestIndex];

      importedWaypoints.add(
        Waypoint(
          id: "imp_${w.lat}_${w.lon}_${DateTime.now().microsecondsSinceEpoch}",
          name: w.name ?? "Waypoint",
          lat: w.lat!,
          lon: w.lon!,
          trackIndex: closestIndex,
          distanceAtPoint: targetPoint.distanceAtPoint,
          ele: w.ele ?? targetPoint.altitude,
          time: w.time ?? targetPoint.timestamp,
        ),
      );
    }

    ref.read(importedWaypointsProvider.notifier).setAll(importedWaypoints);
  }

  static DateTime normalizeGpxTime(DateTime t) {
    final local = t.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      0,
      0,
    );
  }

  static List<UserPosition> simplifyTrack(
    List<UserPosition> points,
    double toleranceMeters,
  ) {
    if (points.length < 3) return points;

    double perpendicularDistance(
      UserPosition p,
      UserPosition start,
      UserPosition end,
    ) {
      final x0 = p.position.longitude;
      final y0 = p.position.latitude;
      final x1 = start.position.longitude;
      final y1 = start.position.latitude;
      final x2 = end.position.longitude;
      final y2 = end.position.latitude;

      final num = ((y2 - y1) * x0) - ((x2 - x1) * y0) + (x2 * y1) - (y2 * x1);
      final den = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2));

      if (den == 0) {
        return haversineDistance(
          p.position.latitude,
          p.position.longitude,
          start.position.latitude,
          start.position.longitude,
        );
      }
      return (num.abs() / den) * 111320.0;
    }

    List<UserPosition> dp(List<UserPosition> pts) {
      double maxDist = 0.0;
      int index = 0;

      for (int i = 1; i < pts.length - 1; i++) {
        final d = perpendicularDistance(pts[i], pts.first, pts.last);
        if (d > maxDist) {
          maxDist = d;
          index = i;
        }
      }

      if (maxDist > toleranceMeters) {
        final left = dp(pts.sublist(0, index + 1));
        final right = dp(pts.sublist(index, pts.length));
        return [...left, ...right.skip(1)];
      } else {
        return [pts.first, pts.last];
      }
    }

    return dp(points);
  }
}
