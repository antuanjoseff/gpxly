import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../notifiers/track_notifier.dart';
import '../notifiers/imported_track_notifier.dart';
import '../notifiers/selected_track_source_notifier.dart';
import 'track_source.dart';

final activeTrackProvider = Provider<Track>((ref) {
  final source = ref.watch(selectedTrackSourceProvider);
  final imported = ref.watch(importedTrackProvider);
  final recorded = ref.watch(trackProvider);

  switch (source) {
    case TrackSource.imported:
      return imported ?? recorded;
    case TrackSource.recorded:
    default:
      return recorded;
  }
});
