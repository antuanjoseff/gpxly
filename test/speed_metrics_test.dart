import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/services/gpx_import_service.dart';

void main() {
  group('speed metrics', () {
    test(
      'five valid samples produce a moving average of the corrected speed',
      () {
        final now = DateTime.utc(2024, 1, 1, 12, 0, 0);
        final points = <UserPosition>[
          UserPosition(
            position: const LatLng(0, 0),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now,
            accuracy: 0,
            distanceAtPoint: 0,
          ),
          UserPosition(
            position: const LatLng(0, 0.0001),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 1)),
            accuracy: 0,
            distanceAtPoint: 10,
          ),
          UserPosition(
            position: const LatLng(0, 0.0002),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 2)),
            accuracy: 0,
            distanceAtPoint: 20,
          ),
          UserPosition(
            position: const LatLng(0, 0.0003),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 3)),
            accuracy: 0,
            distanceAtPoint: 30,
          ),
          UserPosition(
            position: const LatLng(0, 0.0004),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 4)),
            accuracy: 0,
            distanceAtPoint: 40,
          ),
        ];

        final corrected = Track.computeSmoothedSpeeds(points);

        expect(corrected[1], closeTo(40.03, 1.0));
        expect(corrected[4], closeTo(40.03, 1.0));
      },
    );

    test(
      'poor accuracy points are excluded from the 5-point moving average',
      () {
        final now = DateTime.utc(2024, 1, 1, 12, 0, 0);
        final points = <UserPosition>[
          UserPosition(
            position: const LatLng(0, 0),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now,
            accuracy: 0,
            distanceAtPoint: 0,
          ),
          UserPosition(
            position: const LatLng(0, 0.0001),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 1)),
            accuracy: 0,
            distanceAtPoint: 10,
          ),
          UserPosition(
            position: const LatLng(0, 0.0002),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 2)),
            accuracy: 15,
            distanceAtPoint: 20,
          ),
          UserPosition(
            position: const LatLng(0, 0.0003),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 3)),
            accuracy: 0,
            distanceAtPoint: 30,
          ),
          UserPosition(
            position: const LatLng(0, 0.0004),
            altitude: 0,
            isHgtFixed: false,
            timestamp: now.add(const Duration(seconds: 4)),
            accuracy: 0,
            distanceAtPoint: 40,
          ),
        ];

        final corrected = Track.computeSmoothedSpeeds(points);

        expect(corrected[1], closeTo(40.03, 1.0));
        expect(corrected[4], closeTo(40.03, 1.0));
      },
    );
  });
}
