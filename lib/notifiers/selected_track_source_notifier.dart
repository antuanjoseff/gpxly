import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/track_source.dart';

class SelectedTrackSourceNotifier extends Notifier<TrackSource> {
  @override
  TrackSource build() => TrackSource.recorded;

  void select(TrackSource source) {
    state = source;
  }

  /// Quan només hi ha un track, el seleccionem automàticament
  void forceSelectSingle({
    required bool hasRecorded,
    required bool hasImported,
  }) {
    if (hasRecorded && !hasImported) {
      state = TrackSource.recorded;
    } else if (!hasRecorded && hasImported) {
      state = TrackSource.imported;
    }
  }
}

final selectedTrackSourceProvider =
    NotifierProvider<SelectedTrackSourceNotifier, TrackSource>(
      SelectedTrackSourceNotifier.new,
    );
