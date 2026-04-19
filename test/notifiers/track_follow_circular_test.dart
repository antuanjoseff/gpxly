import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../helpers/fake_track.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no detecta final al començar sobre el punt final', () {
    final container = ProviderContainer();
    final notifier = container.read(trackFollowNotifierProvider.notifier);

    container
        .read(importedTrackProvider.notifier)
        .setTrack(makeCircularTrack());

    notifier.startFollowingWithRecording();

    // Inici sobre el punt final
    notifier.updateUserPosition(LatLng(0.0, 0.0));

    final state = container.read(trackFollowNotifierProvider);

    expect(state.showEndOfTrackSnackbar, false);
  });
}
