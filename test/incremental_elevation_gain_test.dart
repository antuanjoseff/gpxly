import 'package:flutter_test/flutter_test.dart';
import 'package:strack_rec/utils/calculations.dart';

void main() {
  group('IncrementalElevationGain', () {
    test('matches centered smoothing after finalizing the pending points', () {
      final gain = IncrementalElevationGain(windowMeters: 80, threshold: 4);
      final altitudes = [100.0, 106.0, 112.0, 108.0, 118.0];
      final distances = [0.0, 30.0, 60.0, 90.0, 120.0];

      for (var index = 0; index < altitudes.length; index++) {
        gain.add(altitudes[index], distances[index]);
      }

      final expected = ElevationUtils.computeGain(
        altitudes,
        distances: distances,
        windowMeters: 80,
        threshold: 4,
      );
      final result = gain.finish();

      expect(result.ascent, closeTo(expected.ascent, 0.001));
      expect(result.descent, closeTo(expected.descent, 0.001));
    });

    test('matches centered smoothing at every live update', () {
      final gain = IncrementalElevationGain(windowMeters: 80, threshold: 4);
      final altitudes = [100.0, 108.0, 102.0, 114.0, 110.0, 122.0];
      final distances = [0.0, 15.0, 35.0, 70.0, 100.0, 145.0];

      for (var index = 0; index < altitudes.length; index++) {
        final result = gain.add(altitudes[index], distances[index]);
        final expected = ElevationUtils.computeGain(
          altitudes.sublist(0, index + 1),
          distances: distances.sublist(0, index + 1),
          windowMeters: 80,
          threshold: 4,
        );

        expect(result.ascent, closeTo(expected.ascent, 0.001));
        expect(result.descent, closeTo(expected.descent, 0.001));
      }
    });

    test('accumulates descent and resets its internal state', () {
      final gain = IncrementalElevationGain(windowMeters: 20, threshold: 4);

      gain.add(120, 0);
      gain.add(110, 30);
      expect(gain.finish().descent, 10.0);

      gain.reset();
      final result = gain.add(100, 0);
      expect(result.ascent, 0.0);
      expect(result.descent, 0.0);
    });
  });
}
