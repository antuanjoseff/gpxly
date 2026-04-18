import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

class ImportedTrackNotifier extends Notifier<Track?> {
  @override
  Track? build() {
    return null; // cap track importat per defecte
  }

  void setTrack(Track t) {
    state = t;
  }

  void clear() {
    state = null;
  }

  void reverseTrack() {
    final t = state;
    if (t == null) return;

    state = Track(
      // Llistes seqüencials → invertir
      coordinates: t.coordinates.reversed.toList(),
      distances: t.distances.reversed.toList(),
      altitudes: t.altitudes.reversed.toList(),
      timestamps: t.timestamps.reversed.toList(),
      accuracies: t.accuracies.reversed.toList(),
      speeds: t.speeds.reversed.toList(),
      headings: t.headings.reversed.toList(),
      satellites: t.satellites.reversed.toList(),
      vAccuracies: t.vAccuracies.reversed.toList(),

      // Valors globals → NO invertir
      recordingState: t.recordingState,
      duration: t.duration,
      distance: t.distance,
      ascent: t.ascent,
      descent: t.descent,
      maxElevation: t.maxElevation,
      minElevation: t.minElevation,

      // Bounding box → NO invertir
      minLat: t.minLat,
      maxLat: t.maxLat,
      minLon: t.minLon,
      maxLon: t.maxLon,
    );
  }
}

final importedTrackProvider = NotifierProvider<ImportedTrackNotifier, Track?>(
  ImportedTrackNotifier.new,
);
