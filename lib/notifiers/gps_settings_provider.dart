import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpsSettings {
  final bool useTime;
  final int seconds;
  final int meters;

  GpsSettings({
    required this.useTime,
    required this.seconds,
    required this.meters,
  });

  GpsSettings copyWith({bool? useTime, int? seconds, int? meters}) {
    return GpsSettings(
      useTime: useTime ?? this.useTime,
      seconds: seconds ?? this.seconds,
      meters: meters ?? this.meters,
    );
  }
}

class GpsSettingsNotifier extends Notifier<GpsSettings> {
  @override
  GpsSettings build() {
    return GpsSettings(useTime: true, seconds: 5, meters: 10);
  }

  void setUseTime(bool value) {
    state = state.copyWith(useTime: value);
  }

  void setSeconds(int value) {
    state = state.copyWith(seconds: value);
  }

  void setMeters(int value) {
    state = state.copyWith(meters: value);
  }
}

final gpsSettingsProvider = NotifierProvider<GpsSettingsNotifier, GpsSettings>(
  () => GpsSettingsNotifier(),
);
