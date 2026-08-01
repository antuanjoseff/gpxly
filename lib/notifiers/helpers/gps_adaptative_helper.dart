import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/gps_debug_notifier.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/services/native_gps_channel.dart';

bool needAdaptiveGps(Ref ref, bool isFollowing) {
  final alarms = ref.read(alarmSettingsProvider);
  return isFollowing || alarms.distanceEnabled;
}

(int seconds, double meters) computeAdaptiveFrequency(double kmh) {
  if (kmh < 10) return (2, 5);
  if (kmh < 40) return (1, 10);
  if (kmh < 80) return (1, 20);
  return (0, 30);
}

Future<void> applyAdaptiveGps({
  required Ref ref,
  required bool isFollowing,
  required double kmh,
}) async {
  if (!needAdaptiveGps(ref, isFollowing)) return;

  final (sec, meters) = computeAdaptiveFrequency(kmh);
  final gpsSettings = ref.read(gpsSettingsProvider);

  final mustRestart =
      gpsSettings.seconds != sec ||
      gpsSettings.meters != meters ||
      gpsSettings.useTime != (sec > 0);

  if (mustRestart) {
    final debugEnabled = ref.read(gpsDebugProvider);
    await NativeGpsChannel.start(
      useTime: sec > 0,
      seconds: sec,
      meters: meters,
      accuracy: gpsSettings.accuracy,
      debug: debugEnabled,
    );
  }
}
