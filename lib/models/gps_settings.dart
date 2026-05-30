// lib/models/gps_settings.dart
class GpsSettings {
  final bool useTime; // true -> Filtra per segons | false -> Filtra per metres
  final int seconds; // Interval de temps (X segons)
  final double meters; // Interval de distància (X metres)
  final double
  accuracy; // Mínima precisió acceptable (rebutjar tot el que sigui > X metres)

  const GpsSettings({
    this.useTime = true,
    this.seconds = 5,
    this.meters = 10,
    this.accuracy = 20,
  });

  GpsSettings copyWith({
    bool? useTime,
    int? seconds,
    double? meters,
    double? accuracy,
  }) {
    return GpsSettings(
      useTime: useTime ?? this.useTime,
      seconds: seconds ?? this.seconds,
      meters: meters ?? this.meters,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}
