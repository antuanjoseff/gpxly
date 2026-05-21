import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/alarm_progress.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/notifiers/helpers/track_sounds.dart';
import 'package:senda/notifiers/track_notifier.dart';

class AlarmEngine {
  final Ref ref;

  StreamSubscription<LatLng>? _posSub;
  Timer? _timer;

  // Distància
  LatLng? _lastPos;
  double _distanceAccumulated = 0.0;

  // Altitud (per trams / buckets)
  int? _lastAltitudeRange;

  // Temps
  DateTime? _lastTimeAlarm;

  final TrackSounds sounds = TrackSounds();

  AlarmEngine(this.ref);

  // ───────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────────

  Future<void> start() async {
    print("🚀 AlarmEngine START");

    await ref.read(alarmSettingsProvider.notifier).initialized;
    _resetInternalState();

    _posSub = ref
        .read(trackProvider.notifier)
        .positionStream
        .listen(_onPosition);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeAlarm();

      _progressController.add(
        AlarmProgress(
          distance: distanceProgress,
          altitude: altitudeProgress,
          time: timeProgress,
        ),
      );
    });
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

    // Altitud (HGT ja corregida al track)
    // Altitud real del dispositiu (corregida amb HGT per TrackNotifier)
    if (settings.altitudeEnabled) {
      final gpsAltitude = ref.read(gpsAltitudeProvider);
      if (gpsAltitude != null) {
        _checkAltitudeAlarm(gpsAltitude, settings.altitudeMeters);
      }
    }

    _lastPos = pos;
  }

  // ───────────────────────────────────────────────
  // DISTÀNCIA (alarma cada X metres acumulats)
  // ───────────────────────────────────────────────

  void _checkDistanceAlarm(LatLng pos, double thresholdMeters) {
    if (_lastPos == null) {
      _lastPos = pos;
      return;
    }

    final step = _distanceBetween(_lastPos!, pos);

    // Filtre de soroll GPS
    if (!step.isFinite) return;
    if (step < 3 || step > 50) {
      _lastPos = pos;
      return;
    }

    _distanceAccumulated += step;

    while (_distanceAccumulated >= thresholdMeters) {
      sounds.playDistanceAlarm();
      _distanceAccumulated -= thresholdMeters;
    }

    _lastPos = pos;
  }

  // ───────────────────────────────────────────────
  // ALTITUD (alarma per trams / buckets)
  // ───────────────────────────────────────────────

  void _checkAltitudeAlarm(double altitude, double thresholdMeters) {
    if (thresholdMeters <= 0) return;

    // 1. Rang actual segons l'alçada real
    final int currentRange = (altitude / thresholdMeters).floor();

    if (_lastAltitudeRange == null) {
      _lastAltitudeRange = currentRange;
      return;
    }

    final int last = _lastAltitudeRange!;

    // 2. Definim una histèresi segura (en metres)
    // Un valor d'entre 1.0 i 2.0 metres és ideal per a baròmetres de mòbil
    const double hysteresis = 5;

    // 3. Lògica de pas de frontera
    if (currentRange > last) {
      // Cas de PUJADA: Hem de superar la frontera + el marge d'histèresi
      double boundary = currentRange * thresholdMeters;
      if (altitude >= (boundary + hysteresis)) {
        _lastAltitudeRange = currentRange;
        sounds.playAltitudeAlarm();
      }
    } else if (currentRange < last) {
      // Cas de BAIXADA: Hem de baixar de la frontera - el marge d'histèresi
      double boundary = (currentRange + 1) * thresholdMeters;
      if (altitude <= (boundary - hysteresis)) {
        _lastAltitudeRange = currentRange;
        sounds.playAltitudeAlarm();
      }
    }
  }

  // ───────────────────────────────────────────────
  // TEMPS (alarma cada X segons)
  // ───────────────────────────────────────────────
  void _checkTimeAlarm() {
    final settings = ref.read(alarmSettingsProvider);

    print(
      "⏱️ [TIME] Enabled=${settings.timeEnabled}, Seconds=${settings.timeSeconds}",
    );

    if (!settings.timeEnabled) return;

    final now = DateTime.now();

    if (_lastTimeAlarm == null) {
      print("⏱️ [TIME] Primera execució → inicialitzant _lastTimeAlarm");
      _lastTimeAlarm = now;
      return;
    }

    final elapsed = now.difference(_lastTimeAlarm!).inSeconds;
    print("⏱️ [TIME] Elapsed=$elapsed / Target=${settings.timeSeconds}");

    if (elapsed >= settings.timeSeconds) {
      print("🔔 [TIME] ALARMA DE TEMPS DISPARADA!");
      _lastTimeAlarm = now;
      sounds.playTimeAlarm();
    }
  }

  // ───────────────────────────────────────────────
  // GETTERS
  // ───────────────────────────────────────────────
  double get distanceProgress {
    final s = ref.read(alarmSettingsProvider);
    if (!s.distanceEnabled) return 0;
    return (_distanceAccumulated / s.distanceMeters).clamp(0, 1);
  }

  double get altitudeProgress {
    final s = ref.read(alarmSettingsProvider);
    if (!s.altitudeEnabled || s.altitudeMeters <= 0) return 0;

    final alt = ref.read(gpsAltitudeProvider);

    return ((alt % s.altitudeMeters) / s.altitudeMeters).clamp(0, 1);
  }

  double get timeProgress {
    final s = ref.read(alarmSettingsProvider);
    if (!s.timeEnabled || _lastTimeAlarm == null) return 0;

    final elapsed = DateTime.now().difference(_lastTimeAlarm!).inSeconds;
    return (elapsed / s.timeSeconds).clamp(0, 1);
  }

  // ───────────────────────────────────────────────
  // PROGRESS STREAM
  // ───────────────────────────────────────────────

  final _progressController = StreamController<AlarmProgress>.broadcast();
  Stream<AlarmProgress> get progressStream => _progressController.stream;

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
    _distanceAccumulated = 0.0;
    _lastAltitudeRange = null;
    _lastTimeAlarm = null;
  }
}
