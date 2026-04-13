import 'package:gpx/gpx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/utils/calculations.dart';
import 'package:gpxly/utils/geo_utils.dart';
import '../models/track.dart';
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
    final distancesList = <double>[]; // <--- AFEGIT

    double accumulatedDistance = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.lat == null || p.lon == null) continue;

      coords.add([p.lon!, p.lat!]);
      alts.add(p.ele ?? 0.0);
      times.add(p.time ?? DateTime.now());

      // Càlcul de la distància acumulada punt a punt
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

    // -----------------------------
    // Bounding box
    // -----------------------------
    final lats = coords.map((c) => c[1]).toList();
    final lons = coords.map((c) => c[0]).toList();

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLon = lons.reduce((a, b) => a < b ? a : b);
    final maxLon = lons.reduce((a, b) => a > b ? a : b);

    // -----------------------------
    // Durada
    // -----------------------------
    Duration totalDuration = Duration.zero;
    if (times.length > 1) {
      totalDuration = times.last.difference(times.first);
    }

    // -----------------------------
    // Desnivells
    // -----------------------------
    final ascent = computeAscent(alts);
    final descent = computeDescent(alts);

    // -----------------------------
    // Crear Track importat
    // -----------------------------
    final imported = Track(
      coordinates: coords,
      distances: distancesList, // <--- ARA EL MODEL REB LA LLISTA
      altitudes: alts,
      timestamps: times,
      accuracies: [],
      speeds: [],
      headings: [],
      satellites: [],
      vAccuracies: [],
      recordingState: RecordingState.idle,
      duration: totalDuration,
      distance: accumulatedDistance, // Fem servir la que hem calculat al bucle
      ascent: ascent,
      descent: descent,
      maxElevation: alts.reduce((a, b) => a > b ? a : b),
      minElevation: alts.reduce((a, b) => a < b ? a : b),
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );

    // -----------------------------
    // Guardar al provider
    // -----------------------------
    ref.read(importedTrackProvider.notifier).setTrack(imported);
  }
}
