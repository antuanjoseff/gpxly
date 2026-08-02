// lib/services/gpx_import_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpx/gpx.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/utils/calculations.dart';
import 'package:strack_rec/utils/geo_utils.dart';

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

    // Sense simplificació: preservem tots els punts originals del GPX.
    final importedPoints = loadedPoints;

    // Bounds recalculats sobre el track complet importat
    minLat = importedPoints
        .map((p) => p.position.latitude)
        .reduce((a, b) => a < b ? a : b);
    maxLat = importedPoints
        .map((p) => p.position.latitude)
        .reduce((a, b) => a > b ? a : b);
    minLon = importedPoints
        .map((p) => p.position.longitude)
        .reduce((a, b) => a < b ? a : b);
    maxLon = importedPoints
        .map((p) => p.position.longitude)
        .reduce((a, b) => a > b ? a : b);
    minEle = importedPoints
        .map((p) => p.altitude)
        .reduce((a, b) => a < b ? a : b);
    maxEle = importedPoints
        .map((p) => p.altitude)
        .reduce((a, b) => a > b ? a : b);

    print(
      ">>> INDESTRUCTIBLE GPX BOUNDS: "
      "minLat=$minLat, maxLat=$maxLat, "
      "minLon=$minLon, maxLon=$maxLon",
    );

    Duration totalDuration = Duration.zero;
    if (importedPoints.length > 1) {
      totalDuration = importedPoints.last.timestamp.difference(
        importedPoints.first.timestamp,
      );
    }

    double averageSpeed = 0.0;
    if (totalDuration.inSeconds > 0) {
      averageSpeed = accumulatedDistance / totalDuration.inSeconds;
    }

    final importedAlts = importedPoints
        .map((p) => p.altitude)
        .toList(growable: false);
    final ascent = computeAscent(importedAlts);
    final descent = computeDescent(importedAlts);

    final importedTrack = Track(
      points: importedPoints,
      recordingState: RecordingState.idle,
      stats: TrackStats(
        duration: totalDuration,
        stoppedDuration: Duration.zero,
        distance: accumulatedDistance,
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

    // Waypoints sobre el track complet importat
    int findClosestTrackIndex(double wpLat, double wpLon) {
      double minDist = double.infinity;
      int minIndex = 0;

      for (int i = 0; i < importedPoints.length; i++) {
        final pos = importedPoints[i].position;
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
      final targetPoint = importedPoints[closestIndex];

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
}
