class GpxSettings {
  final bool accuracies; // Horizontal accuracy
  final bool speeds; // Speed
  final bool headings; // Heading / bearing
  final bool satellites; // Satellite count
  final bool vAccuracies; // Vertical accuracy

  const GpxSettings({
    this.accuracies = false,
    this.speeds = false,
    this.headings = false,
    this.satellites = false,
    this.vAccuracies = false,
  });

  GpxSettings copyWith({
    bool? accuracies,
    bool? speeds,
    bool? headings,
    bool? satellites,
    bool? vAccuracies,
  }) {
    return GpxSettings(
      accuracies: accuracies ?? this.accuracies,
      speeds: speeds ?? this.speeds,
      headings: headings ?? this.headings,
      satellites: satellites ?? this.satellites,
      vAccuracies: vAccuracies ?? this.vAccuracies,
    );
  }
}
