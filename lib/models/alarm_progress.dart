class AlarmProgress {
  final double distance;
  final double
  accProgress; // Progreso hacia el siguiente tramo de desnivel (0.0 a 1.0)
  final double cotaProgress; // Progreso hacia la siguiente cota (0.0 a 1.0)
  final double time;

  const AlarmProgress({
    required this.distance,
    required this.accProgress,
    required this.cotaProgress,
    required this.time,
  });
}
