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

    // Llistes intermèdies per als teus càlculs natius de desnivell (ascent/descent)
    final alts = <double>[];
    final lats = <double>[];
    final lons = <double>[];

    // Aquí acumularem la llista d'objectes concrets UserPosition
    final loadedPoints = <UserPosition>[];
    double accumulatedDistance = 0.0;

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

      lats.add(currentLat);
      lons.add(currentLon);
      alts.add(currentAlt);

      if (i > 0) {
        // Càlcul utilitzant el teu helper haversineDistance existent
        accumulatedDistance += haversineDistance(
          lats[i - 1],
          lons[i - 1],
          currentLat,
          currentLon,
        );
      }

      // Construeixen de forma seqüencial el nou model atòmic per a cada punt
      loadedPoints.add(
        UserPosition(
          position: LatLng(currentLat, currentLon),
          altitude: currentAlt,
          isHgtFixed:
              false, // En ser importat d'un GPX extern, no ve filtrat pel nostre baròmetre
          timestamp: normalizedTime,
          accuracy: 0.0,
          vAccuracy: 0.0,
          speed: 0.0,
          heading: 0.0,
          satellites: p.sat ?? 0,
          distanceAtPoint:
              accumulatedDistance, // Desem la distància acumulada exactament en aquest node
        ),
      );
    }

    if (loadedPoints.isEmpty) return;

    // ─────────────────────────────────────────────────
    // 2. CÀLCUL DE BOUNDING BOX, DURADA I DESNIVELLS
    // ─────────────────────────────────────────────────
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLon = lons.reduce((a, b) => a < b ? a : b);
    final maxLon = lons.reduce((a, b) => a > b ? a : b);

    print(
      ">>> IMPORTED BOUNDS (GPX): "
      "minLat=$minLat, maxLat=$maxLat, "
      "minLon=$minLon, maxLon=$maxLon",
    );

    Duration totalDuration = Duration.zero;
    if (loadedPoints.length > 1) {
      totalDuration = loadedPoints.last.timestamp.difference(
        loadedPoints.first.timestamp,
      );
    }

    // Computació utilitzant els teus algorismes helpers natius existents
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
        maxElevation: alts.reduce((a, b) => a > b ? a : b),
        minElevation: alts.reduce((a, b) => a < b ? a : b),
        minLat: minLat,
        maxLat: maxLat,
        minLon: minLon,
        maxLon: maxLon,
      ),
    );

    // Guardem el Track en el nou proveïdor de la branca
    ref.read(importedTrackProvider.notifier).setTrack(importedTrack);

    // ─────────────────────────────────────────────────
    // 4. PARSEJAR WAYPOINTS I ASSIGNAR TRACKINDEX
    // ─────────────────────────────────────────────────
    // Gràcies al getter de retrocompatibilitat `coordinates` del model Track,
    // aquest cercador geomètric continua compilant intacte.
    int findClosestTrackIndex(double wpLat, double wpLon) {
      double minDist = double.infinity;
      int minIndex = 0;

      for (int i = 0; i < importedTrack.coordinates.length; i++) {
        // ✅ VERIFICA QUE ESTÉ ASÍ: [1] es la Latitud y [0] es la Longitud
        final lat = importedTrack.coordinates[i][1];
        final lon = importedTrack.coordinates[i][0];

        final d = haversineDistance(wpLat, wpLon, lat, lon);

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

      // Llegim les dades enllaçades directament des de la UserPosition corresponent
      final targetPoint = importedTrack.points[closestIndex];

      importedWaypoints.add(
        Waypoint(
          id: "imp_${w.lat}_${w.lon}_${DateTime.now().microsecondsSinceEpoch}",
          name: w.name ?? "Waypoint",
          lat: w.lat!,
          lon: w.lon!,
          trackIndex: closestIndex,
          distanceAtPoint: targetPoint.distanceAtPoint,
          ele:
              w.ele ??
              targetPoint
                  .altitude, // Prioritzem la cota del propi waypoint si existeix
          time: w.time ?? targetPoint.timestamp,
        ),
      );
    }

    // Desar el llistat complet de fites en el teu proveïdor existent
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
