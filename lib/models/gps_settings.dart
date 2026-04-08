class GpsSettings {
  final bool useTime;
  final int seconds;
  final double meters;
  final double accuracy;

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
