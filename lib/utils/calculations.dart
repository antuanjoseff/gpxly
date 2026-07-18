import '../models/user_profile.dart';

double calculateCalories(int steps, UserProfile profile) {
  // Aproximació simple: 0.04 kcal per pas per kg
  return steps * profile.peso * 0.04;
}

double computeAscent(List<double> alts) {
  if (alts.length < 2) return 0.0;
  final smoothAlts = ElevationUtils.smooth(alts);
  final result = ElevationUtils.robustGain(smoothAlts);
  return result['ascent'] ?? 0.0;
}

double computeDescent(List<double> alts) {
  if (alts.length < 2) return 0.0;
  final smoothAlts = ElevationUtils.smooth(alts);
  final result = ElevationUtils.robustGain(smoothAlts);
  return result['descent'] ?? 0.0;
}

// lib/utils/elevation_utils.dart

class ElevationUtils {
  static List<double> smooth(List<double> alts, {int window = 5}) {
    final int n = alts.length;
    final int r = window ~/ 2;
    final List<double> out = [];

    for (int i = 0; i < n; i++) {
      final int start = (i - r) < 0 ? 0 : (i - r);
      final int end = (i + r + 1) > n ? n : (i + r + 1);

      double sum = 0;
      int count = 0;
      for (int j = start; j < end; j++) {
        sum += alts[j];
        count++;
      }
      out.add(sum / count);
    }

    return out;
  }

  static Map<String, double> robustGain(
    List<double> alts, {
    double threshold = 3.5,
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
}
