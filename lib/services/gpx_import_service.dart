import 'package:gpx/gpx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    for (final p in points) {
      if (p.lat == null || p.lon == null) continue;

      coords.add([p.lon!, p.lat!]);
      alts.add(p.ele ?? 0.0);
      times.add(p.time ?? DateTime.now());
    }

    // Calcular distància total
    double totalDistance = 0.0;
    for (int i = 1; i < coords.length; i++) {
      totalDistance += haversineDistance(
        coords[i - 1][1],
        coords[i - 1][0],
        coords[i][1],
        coords[i][0],
      );
    }

    // Calcular durada
    Duration totalDuration = Duration.zero;
    if (times.length > 1) {
      totalDuration = times.last.difference(times.first);
    }

    // Calcular desnivells
    double ascent = 0.0;
    double descent = 0.0;
    for (int i = 1; i < alts.length; i++) {
      final diff = alts[i] - alts[i - 1];
      if (diff > 0) ascent += diff;
      if (diff < 0) descent += diff.abs();
    }

    final imported = Track(
      coordinates: coords,
      altitudes: alts,
      timestamps: times,
      accuracies: [],
      speeds: [],
      headings: [],
      satellites: [],
      vAccuracies: [],
      recordingState: RecordingState.idle,
      duration: totalDuration,
      distance: totalDistance,
      ascent: ascent,
      descent: descent,
      maxElevation: alts.reduce((a, b) => a > b ? a : b),
      minElevation: alts.reduce((a, b) => a < b ? a : b),
    );

    ref.read(importedTrackProvider.notifier).setTrack(imported);
  }
}
