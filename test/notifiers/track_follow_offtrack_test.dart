import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../helpers/fake_track.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detecta OFFTRACK quan t allunyes', () {
    final container = ProviderContainer();
    final notifier = container.read(trackFollowNotifierProvider.notifier);

    // Assignar track
    container.read(importedTrackProvider.notifier).setTrack(makeLinearTrack());

    // Iniciar seguiment
    notifier.startFollowingWithRecording();

    // 1) Entrar en ONTRACK
    notifier.updateUserPosition(LatLng(0.0, 0.0));

    // 2) Avançar per crear trending (mínim 6 punts)
    notifier.updateUserPosition(LatLng(0.0001, 0.0));
    notifier.updateUserPosition(LatLng(0.0002, 0.0));
    notifier.updateUserPosition(LatLng(0.0003, 0.0));
    notifier.updateUserPosition(LatLng(0.0004, 0.0));
    notifier.updateUserPosition(LatLng(0.0005, 0.0));

    // 3) Ara sí: sortir fora del track (distància > 35m + trending away)
    notifier.updateUserPosition(LatLng(0.0005, 0.0007)); // ~70m off

    final state = container.read(trackFollowNotifierProvider);

    expect(state.isOffTrack, true);
  });
}
