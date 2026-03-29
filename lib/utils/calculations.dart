import '../models/user_profile.dart';

double calculateCalories(int steps, UserProfile profile) {
  // Aproximació simple: 0.04 kcal per pas per kg
  return steps * profile.peso * 0.04;
}
