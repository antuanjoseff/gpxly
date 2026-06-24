import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';

final nearestTrackPointProvider = Provider<int>((ref) {
  final track = ref.watch(
    importedTrackProvider,
  ); // o trackProvider si és el principal
  final centerLat = ref.watch(mapCenterLatProvider);
  final centerLon = ref.watch(mapCenterLonProvider);

  if (track == null || track.coordinates.isEmpty) return 0;

  int bestIndex = 0;
  double bestDist = double.infinity;

  for (int i = 0; i < track.coordinates.length; i++) {
    final p = track.coordinates[i]; // p = [lon, lat]

    final lon = p[0];
    final lat = p[1];

    final d = (lat - centerLat).abs() + (lon - centerLon).abs();

    if (d < bestDist) {
      bestDist = d;
      bestIndex = i;
    }
  }

  return bestIndex;
});
