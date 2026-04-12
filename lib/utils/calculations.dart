import '../models/user_profile.dart';

double calculateCalories(int steps, UserProfile profile) {
  // Aproximació simple: 0.04 kcal per pas per kg
  return steps * profile.peso * 0.04;
}

double computeAscent(List<double> alts) {
  double ascent = 0.0;
  for (int i = 1; i < alts.length; i++) {
    final diff = alts[i] - alts[i - 1];
    if (diff > 0.5) ascent += diff;
  }
  return ascent;
}

double computeDescent(List<double> alts) {
  double descent = 0.0;
  for (int i = 1; i < alts.length; i++) {
    final diff = alts[i] - alts[i - 1];
    if (diff < -0.5) descent += diff.abs();
  }
  return descent;
}
