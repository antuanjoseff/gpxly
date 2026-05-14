import 'package:flutter_riverpod/flutter_riverpod.dart';

class ElevationRange {
  final double minAlt;
  final double maxAlt;
  final double visualMin;
  final double visualMax;
  final bool isCompressed;
  final bool hasData;

  const ElevationRange({
    required this.minAlt,
    required this.maxAlt,
    required this.visualMin,
    required this.visualMax,
    required this.isCompressed,
    required this.hasData,
  });

  factory ElevationRange.empty() => const ElevationRange(
    minAlt: double.infinity,
    maxAlt: -double.infinity,
    visualMin: 0,
    visualMax: 100,
    isCompressed: false,
    hasData: false,
  );
}

class ElevationRangeNotifier extends Notifier<ElevationRange> {
  @override
  ElevationRange build() => ElevationRange.empty();

  void reset() {
    state = ElevationRange.empty();
  }

  void updateWithNewAltitude(double newAlt) {
    double minAlt = state.minAlt;
    double maxAlt = state.maxAlt;
    bool changed = false;

    if (!state.hasData) {
      minAlt = newAlt;
      maxAlt = newAlt;
      changed = true;
    } else {
      if (newAlt < minAlt) {
        minAlt = newAlt;
        changed = true;
      }
      if (newAlt > maxAlt) {
        maxAlt = newAlt;
        changed = true;
      }
    }

    if (!changed) return;

    final diff = maxAlt - minAlt;

    const double MIN_RANGE = 30; // metres reals mínims
    const double COMPRESS_FACTOR = 0.40; // 40% d’alçada visual

    double visualMin = minAlt;
    double visualMax = maxAlt;
    bool isCompressed = false;

    if (diff < MIN_RANGE) {
      isCompressed = true;
      final mid = (minAlt + maxAlt) / 2;
      final forcedRange = MIN_RANGE / COMPRESS_FACTOR;
      visualMin = mid - forcedRange / 2;
      visualMax = mid + forcedRange / 2;
    }

    state = ElevationRange(
      minAlt: minAlt,
      maxAlt: maxAlt,
      visualMin: visualMin,
      visualMax: visualMax,
      isCompressed: isCompressed,
      hasData: true,
    );
  }
}

final elevationRangeProvider =
    NotifierProvider<ElevationRangeNotifier, ElevationRange>(
      ElevationRangeNotifier.new,
    );
