enum GpsAccuracyLevel { excellent, good, medium, poor, bad }

GpsAccuracyLevel getAccuracyLevel(double accuracy) {
  if (accuracy <= 5) return GpsAccuracyLevel.excellent;
  if (accuracy <= 10) return GpsAccuracyLevel.good;
  if (accuracy <= 20) return GpsAccuracyLevel.medium;
  if (accuracy <= 40) return GpsAccuracyLevel.poor;
  return GpsAccuracyLevel.bad;
}
