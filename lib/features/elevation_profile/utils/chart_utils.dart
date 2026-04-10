class ChartLogic {
  /// Converteix una coordenada X en el canvas a l'índex més proper de la llista
  static int calculateIndexFromX(
    double x,
    double width,
    List<double> distances,
  ) {
    if (distances.isEmpty) return 0;

    final double usableWidth = width - 48; // Padding 24 + 24
    final double localX = (x - 24).clamp(0, usableWidth);
    final double maxDist = distances.last;
    final double targetDist = (localX / usableWidth) * maxDist;

    int closestIndex = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < distances.length; i++) {
      final diff = (distances[i] - targetDist).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      } else if (diff > minDiff) {
        break;
      }
    }
    return closestIndex;
  }

  /// Calcula el valor de X per a un índex concret (per pintar les agulles)
  static double indexToX(int index, double width, List<double> distances) {
    if (distances.isEmpty || index >= distances.length) return 24.0;
    final double usableWidth = width - 48;
    return (distances[index] / distances.last) * usableWidth + 24;
  }
}
