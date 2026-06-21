// lib/services/gpx_import_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpx/gpx.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// Models immutables refactoritzats
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/models/waypoint.dart';
// Providers i utilitats existents de la teva aplicació
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

    final alts = <double>[];
    final loadedPoints = <UserPosition>[];
    double accumulatedDistance = 0.0;

    double minLat = 90.0, maxLat = -90.0;
    double minLon = 180.0, maxLon = -180.0;
    double minEle = double.infinity, maxEle = -double.infinity;

    // 🚀 NOVES VARIABLES PER ALS ATRIBUTS OBLIDATS
    double maxSpeed = 0.0;

    double? lastLat;
    double? lastLon;
    DateTime?
    lastTime; // 🚀 Per mesurar el temps entre punts i trobar la velocitat

    // 1. PARSEJAR I MAPEAR EL CORRENT DE PUNTS (TRACK)
    for (int i = 0; i < gpxPoints.length; i++) {
      final p = gpxPoints[i];
      if (p.lat == null || p.lon == null) continue;

      final currentLat = p.lat!;
      final currentLon = p.lon!;
      final currentAlt = p.ele ?? 0.0;
      final normalizedTime = truncateSeconds(p.time!.toLocal());

      alts.add(currentAlt);

      if (currentLat < minLat) minLat = currentLat;
      if (currentLat > maxLat) maxLat = currentLat;
      if (currentLon < minLon) minLon = currentLon;
      if (currentLon > maxLon) maxLon = currentLon;
      if (currentAlt < minEle) minEle = currentAlt;
      if (currentAlt > maxEle) maxEle = currentAlt;

      double segmentSpeed = 0.0; // Velocitat calculada per a aquest punt

      if (i > 0 && lastLat != null && lastLon != null && lastTime != null) {
        // Calculem els metres fets en aquest pas
        final double distanceDelta = haversineDistance(
          lastLat,
          lastLon,
          currentLat,
          currentLon,
        );
        accumulatedDistance += distanceDelta;

        // Calculem el temps passat en segons
        final int timeDeltaSeconds = normalizedTime
            .difference(lastTime)
            .inSeconds;

        // 🚀 CÀLCUL DE LA VELOCITAT DINÀMICA DEL PUNT
        if (timeDeltaSeconds > 0) {
          segmentSpeed = distanceDelta / timeDeltaSeconds; // m/s
          if (segmentSpeed > maxSpeed) {
            maxSpeed = segmentSpeed; // Guardem el pic més alt
          }
        }
      }

      lastLat = currentLat;
      lastLon = currentLon;
      lastTime = normalizedTime; // Guardem el temps per a la següent iteració

      loadedPoints.add(
        UserPosition(
          position: LatLng(currentLat, currentLon),
          altitude: currentAlt,
          isHgtFixed: false,
          timestamp: normalizedTime,
          accuracy: 0.0,
          vAccuracy: 0.0,
          speed:
              segmentSpeed, // 🚀 ARA SÍ: Cada punt guarda la seva velocitat calculada
          heading: 0.0,
          satellites: p.sat ?? 0,
          distanceAtPoint: accumulatedDistance,
        ),
      );
    }

    if (loadedPoints.isEmpty) return;

    print(
      ">>> INDESTRUCTIBLE GPX BOUNDS: "
      "minLat=$minLat, maxLat=$maxLat, "
      "minLon=$minLon, maxLon=$maxLon",
    );

    Duration totalDuration = Duration.zero;
    if (loadedPoints.length > 1) {
      totalDuration = loadedPoints.last.timestamp.difference(
        loadedPoints.first.timestamp,
      );
    }

    // 🚀 CÀLCUL FINAL DE LA VELOCITAT MITJANA (m/s)
    double averageSpeed = 0.0;
    if (totalDuration.inSeconds > 0) {
      averageSpeed = accumulatedDistance / totalDuration.inSeconds;
    }

    final ascent = computeAscent(alts);
    final descent = computeDescent(alts);

    // 3. CONSTRUCCIÓ DE L'ESTAT CENTRAL DEL TRACK
    final importedTrack = Track(
      points: loadedPoints,
      recordingState: RecordingState.idle,
      stats: TrackStats(
        duration: totalDuration,
        stoppedDuration: Duration
            .zero, // Es queda a zero de manera conscient (manca d'acceleròmetre al fitxer)
        distance: accumulatedDistance,
        ascent: ascent,
        descent: descent,
        maxElevation: maxEle == -double.infinity ? 0.0 : maxEle,
        minElevation: minEle == double.infinity ? 0.0 : minEle,
        averageSpeed: averageSpeed, // 🚀 ENLLAÇAT CORRECTAMENT
        maxSpeed: maxSpeed, // 🚀 ENLLAÇAT CORRECTAMENT
        minLat: minLat,
        maxLat: maxLat,
        minLon: minLon,
        maxLon: maxLon,
      ),
    );

    ref.read(importedTrackProvider.notifier).setTrack(importedTrack);

    // ─────────────────────────────────────────────────
    // 4. PARSEJAR WAYPOINTS SENSE COL·LAPSE GEOMÈTRIC
    // ─────────────────────────────────────────────────
    // ✅ OPTIMITZACIÓ DE CERCA: En lloc d'usar 'importedTrack.coordinates' que demana getters
    // dinàmics i simula vectors a cada volta del bucle, llegim directament la llista compacta 'loadedPoints' en RAM.
    int findClosestTrackIndex(double wpLat, double wpLon) {
      double minDist = double.infinity;
      int minIndex = 0;

      for (int i = 0; i < loadedPoints.length; i++) {
        final pos = loadedPoints[i].position;
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
      final targetPoint = loadedPoints[closestIndex];

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
