import 'package:flutter_test/flutter_test.dart';
import 'package:strack_rec/utils/calculations.dart';

void main() {
  group('IncrementalElevationGain', () {
    test('accumulates a sustained climb and descent', () {
      final gain = IncrementalElevationGain(threshold: 4, smoothingPoints: 3);
      var result = (ascent: 0.0, descent: 0.0);

      for (var altitude = 100.0; altitude <= 130; altitude += 1) {
        result = gain.add(altitude);
      }
      expect(result.ascent, greaterThan(20.0));
      expect(result.descent, 0.0);

      for (var altitude = 130.0; altitude >= 110; altitude -= 1) {
        result = gain.add(altitude);
      }
      expect(result.descent, greaterThan(10.0));
    });

    test('ignores small GPS noise', () {
      final gain = IncrementalElevationGain(threshold: 4, smoothingPoints: 3);
      var result = (ascent: 0.0, descent: 0.0);

      for (var index = 0; index < 50; index++) {
        result = gain.add(100.0 + (index.isEven ? 0.8 : -0.8));
      }

      expect(result.ascent, 0.0);
      expect(result.descent, 0.0);
    });

    test('resets its internal state', () {
      final gain = IncrementalElevationGain(threshold: 4, smoothingPoints: 1);

      gain.add(100);
      gain.add(110);
      expect(gain.finish().ascent, 10.0);

      gain.reset();
      final result = gain.add(100);
      expect(result.ascent, 0.0);
      expect(result.descent, 0.0);
    });
  });
}
