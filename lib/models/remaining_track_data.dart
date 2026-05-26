class RemainingTrackData {
  /// Perfil de altitud del tramo de la guía que queda por delante.
  final List<double> altitudes;

  /// Distancias del tramo futuro.
  /// IMPORTANTE: Empiezan en 0.0 (corresponden al punto de anclaje).
  final List<double> distances;

  /// Tiempos originales del GPX para este tramo.
  final List<DateTime> timestamps;

  /// El índice del track importado donde el GPS ha "enganchado".
  final int anchorIndex;

  const RemainingTrackData({
    required this.altitudes,
    required this.distances,
    required this.timestamps,
    required this.anchorIndex,
  });

  /// Calcula cuánto tiempo preveía el GPX para completar este tramo.
  Duration get estimatedRemainingDuration {
    if (timestamps.length < 2) return Duration.zero;
    return timestamps.last.difference(timestamps.first);
  }
}
