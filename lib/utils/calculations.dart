import '../models/user_profile.dart';
import '../notifiers/helpers/thresholds.dart';

double calculateCalories(int steps, UserProfile profile) {
  // Aproximació simple: 0.04 kcal per pas per kg
  return steps * profile.peso * 0.04;
}

double computeAscent(
  List<double> alts, {
  List<double>? distances,
  double windowMeters = TrackThresholds.elevationSmoothingWindowMeters,
  int window = TrackThresholds.elevationSmoothingWindowPoints,
  double threshold = TrackThresholds.elevationGainThresholdMeters,
}) {
  if (alts.length < 2) return 0.0;
  final smoothAlts = ElevationUtils.smooth(
    alts,
    distances: distances,
    windowMeters: windowMeters,
    window: window,
  );
  final result = ElevationUtils.robustGain(smoothAlts, threshold: threshold);
  return result['ascent'] ?? 0.0;
}

double computeDescent(
  List<double> alts, {
  List<double>? distances,
  double windowMeters = TrackThresholds.elevationSmoothingWindowMeters,
  int window = TrackThresholds.elevationSmoothingWindowPoints,
  double threshold = TrackThresholds.elevationGainThresholdMeters,
}) {
  if (alts.length < 2) return 0.0;
  final smoothAlts = ElevationUtils.smooth(
    alts,
    distances: distances,
    windowMeters: windowMeters,
    window: window,
  );
  final result = ElevationUtils.robustGain(smoothAlts, threshold: threshold);
  return result['descent'] ?? 0.0;
}

// lib/utils/elevation_utils.dart

class ElevationUtils {
  static const double defaultWindowMeters =
      TrackThresholds.elevationSmoothingWindowMeters;
  static const int defaultWindowPoints =
      TrackThresholds.elevationSmoothingWindowPoints;
  static const double defaultThreshold =
      TrackThresholds.elevationGainThresholdMeters;

  /// Suavitza les altituds mitjançant una mitjana mòbil per distància mètrica (si es passen [distances])
  /// o per nombre de punts (si [distances] és null).
  static List<double> smooth(
    List<double> alts, {
    List<double>? distances,
    double windowMeters = defaultWindowMeters,
    int window = defaultWindowPoints,
  }) {
    final int n = alts.length;
    if (n <= 1) return List<double>.from(alts);

    if (distances != null && distances.length == n && windowMeters > 0) {
      return _smoothByDistance(alts, distances, windowMeters);
    }

    return _smoothByPoints(alts, window);
  }

  static List<double> _smoothByPoints(List<double> alts, int window) {
    final int n = alts.length;
    final int r = (window < 1 ? 1 : window) ~/ 2;
    final List<double> out = List<double>.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final int start = (i - r) < 0 ? 0 : (i - r);
      final int end = (i + r + 1) > n ? n : (i + r + 1);

      double sum = 0;
      int count = 0;
      for (int j = start; j < end; j++) {
        sum += alts[j];
        count++;
      }
      out[i] = sum / count;
    }

    return out;
  }

  static List<double> _smoothByDistance(
    List<double> alts,
    List<double> distances,
    double windowMeters,
  ) {
    final int n = alts.length;
    final List<double> out = List<double>.filled(n, 0.0);
    final double halfWindow = windowMeters / 2.0;

    int startIndex = 0;
    int endIndex = 0;

    for (int i = 0; i < n; i++) {
      final double currentDist = distances[i];
      final double minTargetDist = currentDist - halfWindow;
      final double maxTargetDist = currentDist + halfWindow;

      while (startIndex < n && distances[startIndex] < minTargetDist) {
        startIndex++;
      }
      while (endIndex < n && distances[endIndex] <= maxTargetDist) {
        endIndex++;
      }

      final int count = endIndex - startIndex;
      if (count <= 0) {
        out[i] = alts[i];
      } else {
        double sum = 0.0;
        for (int j = startIndex; j < endIndex; j++) {
          sum += alts[j];
        }
        out[i] = sum / count;
      }
    }

    return out;
  }

  /// Calcula el desnivell acumulat (+ i -) aplicant el filtre de llindar
  static Map<String, double> robustGain(
    List<double> alts, {
    double threshold = defaultThreshold,
  }) {
    if (alts.length < 2) {
      return {"ascent": 0.0, "descent": 0.0};
    }

    double ascent = 0.0;
    double descent = 0.0;

    double lastValid = alts.first;

    for (int i = 1; i < alts.length; i++) {
      final double diff = alts[i] - lastValid;

      if (diff.abs() >= threshold) {
        if (diff > 0) {
          ascent += diff;
        } else {
          descent += diff.abs();
        }
        lastValid = alts[i];
      }
    }

    return {"ascent": ascent, "descent": descent};
  }

  /// Càlcul complet i centralitzat de desnivell positiu i negatiu
  static ({double ascent, double descent}) computeGain(
    List<double> alts, {
    List<double>? distances,
    double windowMeters = defaultWindowMeters,
    int window = defaultWindowPoints,
    double threshold = defaultThreshold,
  }) {
    if (alts.length < 2) {
      return (ascent: 0.0, descent: 0.0);
    }
    final smoothAlts = smooth(
      alts,
      distances: distances,
      windowMeters: windowMeters,
      window: window,
    );
    final result = robustGain(smoothAlts, threshold: threshold);
    return (
      ascent: result['ascent'] ?? 0.0,
      descent: result['descent'] ?? 0.0,
    );
  }
}
