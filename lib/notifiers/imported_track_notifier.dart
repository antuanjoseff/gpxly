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
}

final importedTrackProvider = NotifierProvider<ImportedTrackNotifier, Track?>(
  ImportedTrackNotifier.new,
);
