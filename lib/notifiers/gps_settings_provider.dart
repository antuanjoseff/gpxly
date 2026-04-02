import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsSettings {
  final bool useTime;
  final int seconds;
  final double meters;
  final double accuracy;
  GpsSettings({
    required this.useTime,
    required this.seconds,
    required this.meters,
    required this.accuracy,
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

class GpsSettingsNotifier extends Notifier<GpsSettings> {
  static const int minSeconds = 1;
  static const double minMeters = 1.0;

  @override
  GpsSettings build() {
    return GpsSettings(useTime: true, seconds: 5, meters: 10, accuracy: 30);
  }

  void setUseTime(bool value) {
    if (value) {
      // Si selecciona temps, els metres van al mínim
      state = state.copyWith(useTime: true, meters: minMeters);
    } else {
      // Si selecciona metres, els segons van al mínim
      state = state.copyWith(useTime: false, seconds: minSeconds);
    }
  }

  void setSeconds(int value) {
    state = state.copyWith(seconds: value < minSeconds ? minSeconds : value);
  }

  void setMeters(double value) {
    state = state.copyWith(meters: value < minMeters ? minMeters : value);
  }

  void setAccuracy(double value) {
    state = state.copyWith(accuracy: value);
  }
}

final gpsSettingsProvider = NotifierProvider<GpsSettingsNotifier, GpsSettings>(
  () => GpsSettingsNotifier(),
);
