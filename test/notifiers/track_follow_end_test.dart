import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import '../helpers/fake_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ...

  test('detecta final del track després de 100m', () {
    final container = ProviderContainer();
    final notifier = container.read(trackFollowNotifierProvider.notifier);

    container.read(importedTrackProvider.notifier).setTrack(makeDenseTrack());

    notifier.startFollowingWithRecording();

    notifier.updateUserPosition(const LatLng(0.0000, 0.0000));

    notifier.updateUserPosition(const LatLng(0.0000, 0.0003));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0006));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0009));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0012));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0015));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0018));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0021));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0024));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0027));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0030));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0033));
    notifier.updateUserPosition(const LatLng(0.0000, 0.0036));

    notifier.updateUserPosition(const LatLng(0.0000, 0.00399));

    final state = container.read(trackFollowNotifierProvider);

    expect(state.showEndOfTrackSnackbar, true);
  });
}
