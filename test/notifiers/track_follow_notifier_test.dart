import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../helpers/fake_track.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // 🔥 OBLIGATORI
  test('entra en ONTRACK quan estàs sobre el track', () {
    final container = ProviderContainer();
    final notifier = container.read(trackFollowNotifierProvider.notifier);

    container.read(importedTrackProvider.notifier).setTrack(makeLinearTrack());

    notifier.startFollowingWithRecording();
    notifier.updateUserPosition(LatLng(0.0, 0.0));

    final state = container.read(trackFollowNotifierProvider);

    expect(state.mode, FollowMode.onTrack);
    expect(state.isOffTrack, false);
  });
}
