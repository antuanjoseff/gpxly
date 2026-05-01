import 'package:gpx/gpx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/waypoints_imporeted_notifier.dart';
import 'package:gpxly/utils/calculations.dart';
import 'package:gpxly/utils/geo_utils.dart';
import '../models/track.dart';
import '../models/waypoint.dart';
import '../notifiers/imported_track_notifier.dart';

class GpxImportService {
  static Future<void> importGpx(WidgetRef ref, String xmlString) async {
    final gpx = GpxReader().fromString(xmlString);

    if (gpx.trks.isEmpty || gpx.trks.first.trksegs.isEmpty) return;

    final points = gpx.trks.first.trksegs.first.trkpts;
    if (points.isEmpty) return;

    final coords = <List<double>>[];
    final alts = <double>[];
    final times = <DateTime>[];
    final distancesList = <double>[];

    double accumulatedDistance = 0.0;

    // -------------------------------------------------
    // Parsejar TRACK
    // -------------------------------------------------
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.lat == null || p.lon == null) continue;

      coords.add([p.lon!, p.lat!]);
      alts.add(p.ele ?? 0.0);

      final rawTime = p.time ?? DateTime.now();
      times.add(normalizeGpxTime(rawTime));

      if (i > 0) {
        accumulatedDistance += haversineDistance(
          coords[i - 1][1],
          coords[i - 1][0],
          coords[i][1],
          coords[i][0],
        );
      }
      distancesList.add(accumulatedDistance);
    }

    // -------------------------------------------------
    // Bounding box
    // -------------------------------------------------
    final lats = coords.map((c) => c[1]).toList();
    final lons = coords.map((c) => c[0]).toList();

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLon = lons.reduce((a, b) => a < b ? a : b);
    final maxLon = lons.reduce((a, b) => a > b ? a : b);

    // -------------------------------------------------
    // Durada
    // -------------------------------------------------
    Duration totalDuration = Duration.zero;
    if (times.length > 1) {
      totalDuration = times.last.difference(times.first);
    }

    // -------------------------------------------------
    // Desnivells
    // -------------------------------------------------
    final ascent = computeAscent(alts);
    final descent = computeDescent(alts);

    // -------------------------------------------------
    // Crear Track importat
    // -------------------------------------------------
    final imported = Track(
      coordinates: coords,
      distances: distancesList,
      altitudes: alts,
      timestamps: times,
      accuracies: [],
      speeds: [],
      headings: [],
      satellites: [],
      vAccuracies: [],
      recordingState: RecordingState.idle,
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
    );

    // -------------------------------------------------
    // Guardar TRACK al provider
    // -------------------------------------------------
    ref.read(importedTrackProvider.notifier).setTrack(imported);

    // -------------------------------------------------
    // Parsejar WAYPOINTS i assignar trackIndex
    // -------------------------------------------------
    int findClosestTrackIndex(double wpLat, double wpLon) {
      double minDist = double.infinity;
      int minIndex = 0;

      for (int i = 0; i < coords.length; i++) {
        final lat = coords[i][1];
        final lon = coords[i][0];

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

      importedWaypoints.add(
        Waypoint(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: w.name ?? "Waypoint",
          lat: w.lat!,
          lon: w.lon!,
          trackIndex: closestIndex,
        ),
      );
    }

    // -------------------------------------------------
    // Guardar WAYPOINTS al provider
    // -------------------------------------------------
    ref
        .read(importedWaypointsProvider.notifier)
        .setWaypoints(importedWaypoints);
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
