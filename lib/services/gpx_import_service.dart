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

class GpxImportService {
  static Future<void> importGpx(WidgetRef ref, String xmlString) async {
    final gpx = GpxReader().fromString(xmlString);

    if (gpx.trks.isEmpty || gpx.trks.first.trksegs.isEmpty) return;

    final gpxPoints = gpx.trks.first.trksegs.first.trkpts;
    if (gpxPoints.isEmpty) return;

    final alts = <double>[];
    final loadedPoints = <UserPosition>[];
    double accumulatedDistance = 0.0;

    // Variables para calcular Bounds y Elevaciones extremas en UNA SOLA PASADA (Evita .reduce)
    double minLat = 90.0, maxLat = -90.0;
    double minLon = 180.0, maxLon = -180.0;
    double minEle = double.infinity, maxEle = -double.infinity;

    double? lastLat;
    double? lastLon;

    // ─────────────────────────────────────────────────
    // 1. PARSEJAR I MAPEAR EL CORRENT DE PUNTS (TRACK)
    // ─────────────────────────────────────────────────
    for (int i = 0; i < gpxPoints.length; i++) {
      final p = gpxPoints[i];
      if (p.lat == null || p.lon == null) continue;

      final currentLat = p.lat!;
      final currentLon = p.lon!;
      final currentAlt = p.ele ?? 0.0;
      final rawTime = p.time ?? DateTime.now();
      final normalizedTime = normalizeGpxTime(rawTime);

      alts.add(currentAlt);

      // Càlcul de Bounds i elevacions en calent (Evita iteraciones extras posteriores)
      if (currentLat < minLat) minLat = currentLat;
      if (currentLat > maxLat) maxLat = currentLat;
      if (currentLon < minLon) minLon = currentLon;
      if (currentLon > maxLon) maxLon = currentLon;
      if (currentAlt < minEle) minEle = currentAlt;
      if (currentAlt > maxEle) maxEle = currentAlt;

      if (i > 0 && lastLat != null && lastLon != null) {
        accumulatedDistance += haversineDistance(
          lastLat,
          lastLon,
          currentLat,
          currentLon,
        );
      }

      lastLat = currentLat;
      lastLon = currentLon;

      loadedPoints.add(
        UserPosition(
          position: LatLng(currentLat, currentLon),
          altitude: currentAlt,
          isHgtFixed: false,
          timestamp: normalizedTime,
          accuracy: 0.0,
          vAccuracy: 0.0,
          speed: 0.0,
          heading: 0.0,
          satellites: p.sat ?? 0,
          distanceAtPoint: accumulatedDistance,
        ),
      );
    }

    if (loadedPoints.isEmpty) return;

    // ─────────────────────────────────────────────────
    // 2. COMPROVACIÓ DE BOUNDS NATIUS DEL XML DEL GPX
    // ─────────────────────────────────────────────────
    // ✅ OPTIMITZACIÓ: Si l'arxiu ja porta l'etiqueta oficial <bounds>, la usem directament
    // estalviant qualsevol desquadre o esforç analític del fil principal.

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

    final ascent = computeAscent(alts);
    final descent = computeDescent(alts);

    // ─────────────────────────────────────────────────
    // 3. CONSTRUCCIÓ DE L'ESTAT CENTRAL DEL TRACK
    // ─────────────────────────────────────────────────
    final importedTrack = Track(
      points: loadedPoints,
      recordingState: RecordingState.idle,
      stats: TrackStats(
        duration: totalDuration,
        distance: accumulatedDistance,
        ascent: ascent,
        descent: descent,
        maxElevation: maxEle == -double.infinity ? 0.0 : maxEle,
        minElevation: minEle == double.infinity ? 0.0 : minEle,
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
