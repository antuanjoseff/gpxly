import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmState {
  final bool distanceAlarm;
  final bool timeAlarm;
  final bool altitudeAlarm;
  final bool offtrackAlarm;

  const AlarmState({
    this.distanceAlarm = false,
    this.timeAlarm = false,
    this.altitudeAlarm = false,
    this.offtrackAlarm = false,
  });

  AlarmState copyWith({
    bool? distanceAlarm,
    bool? timeAlarm,
    bool? altitudeAlarm,
    bool? offtrackAlarm,
  }) {
    return AlarmState(
      distanceAlarm: distanceAlarm ?? this.distanceAlarm,
      timeAlarm: timeAlarm ?? this.timeAlarm,
      altitudeAlarm: altitudeAlarm ?? this.altitudeAlarm,
      offtrackAlarm: offtrackAlarm ?? this.offtrackAlarm,
    );
  }
}

final alarmEngineProvider = NotifierProvider<AlarmEngine, AlarmState>(
  AlarmEngine.new,
);

class AlarmEngine extends Notifier<AlarmState> {
  @override
  AlarmState build() => const AlarmState();

  // --- Distància ---
  void triggerDistance() {
    state = state.copyWith(distanceAlarm: true);
  }

  void clearDistance() {
    state = state.copyWith(distanceAlarm: false);
  }

  // --- Temps ---
  void triggerTime() {
    state = state.copyWith(timeAlarm: true);
  }

  void clearTime() {
    state = state.copyWith(timeAlarm: false);
  }

  // --- Altitud ---
  void triggerAltitude() {
    state = state.copyWith(altitudeAlarm: true);
  }

  void clearAltitude() {
    state = state.copyWith(altitudeAlarm: false);
  }

  // --- Offtrack ---
  void triggerOfftrack() {
    state = state.copyWith(offtrackAlarm: true);
  }

  void clearOfftrack() {
    state = state.copyWith(offtrackAlarm: false);
  }

  // --- Reset complet ---
  void reset() {
    state = const AlarmState();
  }
}
