import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/helpers/track_sounds.dart';
import 'package:senda/notifiers/track_notifier.dart';

class AlarmEngine {
  final WidgetRef ref;

  StreamSubscription<LatLng>? _posSub;
  Timer? _timer;

  LatLng? _lastPos;
  double _distanceSinceLastAlarm = 0.0;
  double? _lastAltitude;
  DateTime? _lastTimeAlarm;

  final TrackSounds sounds = TrackSounds();

  AlarmEngine(this.ref);

  // ───────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────────

  Future<void> start() async {
    // Ens assegurem que settings estan carregats
    print("🚀 AlarmEngine START");

    await ref.read(alarmSettingsProvider.notifier).initialized;

    // Escoltar posicions del TrackNotifier
    _posSub = ref
        .read(trackProvider.notifier)
        .positionStream
        .listen(_onPosition);

    // Temporitzador per alarmes de temps
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeAlarm();
    });

    _resetInternalState();
  }

  void stop() {
    print("🚀 AlarmEngine STOP");

    _posSub?.cancel();
    _timer?.cancel();
    _resetInternalState();
  }

  // ───────────────────────────────────────────────
  // HANDLERS
  // ───────────────────────────────────────────────

  void _onPosition(LatLng pos) {
    final settings = ref.read(alarmSettingsProvider);

    // Distància
    if (settings.distanceEnabled) {
      _checkDistanceAlarm(pos, settings.distanceMeters);
    }

    // Altitud
    if (settings.altitudeEnabled) {
      _checkAltitudeAlarm(pos, settings.altitudeMeters);
    }

    _lastPos = pos;
  }

  // ───────────────────────────────────────────────
  // DISTÀNCIA
  // ───────────────────────────────────────────────

  void _checkDistanceAlarm(LatLng pos, double thresholdMeters) {
    if (_lastPos == null) return;

    final step = _distanceBetween(_lastPos!, pos);
    if (step.isFinite && step < 200) {
      _distanceSinceLastAlarm += step;
    }

    if (_distanceSinceLastAlarm >= thresholdMeters) {
      _distanceSinceLastAlarm = 0.0;
      sounds.playDistanceAlarm();
    }
  }

  // ───────────────────────────────────────────────
  // ALTITUD
  // ───────────────────────────────────────────────

  void _checkAltitudeAlarm(LatLng pos, double thresholdMeters) {
    final track = ref.read(trackProvider);
    final alt = track.altitudes.isNotEmpty ? track.altitudes.last : null;

    if (alt == null) return;

    if (_lastAltitude == null) {
      _lastAltitude = alt;
      return;
    }

    final diff = (alt - _lastAltitude!).abs();
    if (diff >= thresholdMeters) {
      _lastAltitude = alt;
      sounds.playAltitudeAlarm();
    }
  }

  // ───────────────────────────────────────────────
  // TEMPS
  // ───────────────────────────────────────────────

  void _checkTimeAlarm() {
    final settings = ref.read(alarmSettingsProvider);
    if (!settings.timeEnabled) return;

    final now = DateTime.now();

    if (_lastTimeAlarm == null) {
      print("⏱️ AlarmEngine Primera execució: inicialitzant _lastTimeAlarm");
      _lastTimeAlarm = now;
      return;
    }

    final elapsed = now.difference(_lastTimeAlarm!).inSeconds;
    print(
      "⏱️ AlarmEngine Temps transcorregut: $elapsed / ${settings.timeSeconds}",
    );

    if (elapsed >= settings.timeSeconds) {
      print("🔔 AlarmEngine ALARMA DE TEMPS DISPARADA!");
      _lastTimeAlarm = now;
      sounds.playTimeAlarm();
    }
  }

  // ───────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────

  double _distanceBetween(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _deg(b.latitude - a.latitude);
    final dLon = _deg(b.longitude - a.longitude);

    final lat1 = _deg(a.latitude);
    final lat2 = _deg(b.latitude);

    final h =
        (1 - cos(lat1 - lat2)) / 2 +
        cos(lat1) * cos(lat2) * (1 - cos(dLon)) / 2;

    return 2 * R * sqrt(h);
  }

  double _deg(double d) => d * 3.141592653589793 / 180.0;

  void _resetInternalState() {
    _lastPos = null;
    _distanceSinceLastAlarm = 0.0;
    _lastAltitude = null;
    _lastTimeAlarm = null;
  }
}
