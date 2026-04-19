import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';

void simulatePositions(TrackFollowNotifier notifier, List<LatLng> positions) {
  for (final p in positions) {
    notifier.updateUserPosition(p);
  }
}
