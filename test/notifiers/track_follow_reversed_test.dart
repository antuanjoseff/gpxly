import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detecta reversed direction', () {
    final container = ProviderContainer();
    final notifier = container.read(trackFollowNotifierProvider.notifier);

    // Definim un track molt simple: línia nord-sud
    // coordinates = [ [lon, lat], ... ]
    final importedNotifier = container.read(importedTrackProvider.notifier);
    importedNotifier.setTrack(
      // simulem un model amb camp coordinates
      // si el teu model és diferent, adapta només aquesta part
      container
          .read(trackProvider)
          .copyWith(
            coordinates: const [
              [0.0, 0.0], // (lon, lat)
              [0.0, 0.004], // ~444m cap al nord
            ],
          ),
    );

    notifier.startFollowingWithRecording();

    // 1) Primer punt: sobre l'inici del track → INITIALIZING
    notifier.updateUserPosition(const LatLng(0.0, 0.0));

    // 2) Segon punt: encara molt a prop → _handleFollowState posa ONTRACK
    notifier.updateUserPosition(const LatLng(0.0005, 0.0));

    // 3) Avançar clarament cap al nord (bearing ~0°)
    notifier.updateUserPosition(const LatLng(0.0015, 0.0));
    notifier.updateUserPosition(const LatLng(0.0025, 0.0));

    // 4) Ara retrocedir clarament cap al sud (bearing ~180°)
    notifier.updateUserPosition(const LatLng(0.0015, 0.0));
    notifier.updateUserPosition(const LatLng(0.0010, 0.0));

    final state = container.read(trackFollowNotifierProvider);

    expect(state.showReverseTrackDialog, true);
  });
}
