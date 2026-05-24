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
  final Ref rootRef; // Renomenat per claredat

  StreamSubscription<LatLng>? _posSub;
  Timer? _timer;

  // Distància
  LatLng? _lastPos;
  double _distanceAccumulated = 0.0;

  // LÒGICA 1: Desnivell Acumulat (acc)
  double _smoothedAlt = -1.0;
  double _accUp = 0.0;
  double _accDown = 0.0;

  // LÒGICA 2: Cotes Absolutes (cota)
  int? _lastCotaFloor;

  // Temps
  DateTime? _lastTimeAlarm;

  final TrackSounds sounds = TrackSounds();

  AlarmEngine(this.rootRef);

  // ───────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────────

  Future<void> start() async {
    print("🚀 AlarmEngine START");

    // 1. Eliminem l'await de la inicialització.
    // Quan crides a start(), el Notifier ja està a punt.

    _resetInternalState(); // 🔥 Aquí s'ha d'inicialitzar _lastTimeAlarm = DateTime.now()

    _posSub = rootRef
        .read(trackProvider.notifier)
        .positionStream
        .listen(_onPosition);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeAlarm();
      _emitProgress(); // 📤 Aquesta funció fa que els indicadors es moguin
    });
  }

  void stop() {
    print("🚀 AlarmEngine STOP");
    _posSub?.cancel();
    _timer?.cancel();
    _resetInternalState();
  }

  void _onPosition(LatLng pos) {
    final settings = rootRef.read(alarmSettingsProvider);
    final gpsAltitude = rootRef.read(gpsAltitudeProvider);

    if (settings.distanceEnabled) {
      _checkDistanceAlarm(pos, settings.distanceMeters);
    }

    if (gpsAltitude != null && gpsAltitude > 0.1) {
      _processAltitudeLogics(gpsAltitude, settings);
    }

    _lastPos = pos;
    _emitProgress();
  }

  void _resetInternalState() {
    _lastPos = null;
    _distanceAccumulated = 0.0;
    _smoothedAlt = -1.0;
    _accUp = 0.0;
    _accDown = 0.0;
    _lastCotaFloor = null;
    _lastTimeAlarm = DateTime.now();
  }

  void _processAltitudeLogics(double currentAlt, AlarmSettings settings) {
    // 1. Guardem el valor anterior ABANS de fer res
    // Aquesta és la teva "memòria" del segon anterior
    double altAnterior = _smoothedAlt;

    // 2. A. Filtre de Suavitzat (Només un cop!)
    if (_smoothedAlt < 0) {
      _smoothedAlt = currentAlt;
      return; // No podem calcular res fins a la segona lectura
    } else {
      const double alpha = 0.15;
      _smoothedAlt = (_smoothedAlt * (1 - alpha)) + (currentAlt * alpha);
    }

    // 3. B. Lògica de Desnivell Acumulat (acc)
    if (settings.accEnabled && settings.accMeters > 0) {
      // El delta és la diferència entre el valor suavitzat d'ara i el d'abans
      double delta = _smoothedAlt - altAnterior;

      if (delta.abs() > 0.3) {
        if (delta > 0) {
          _accUp += delta;
          _accDown = 0;
          if (_accUp >= settings.accMeters) {
            sounds.playAltitudeAlarm();
            _accUp = 0;
          }
        } else {
          _accDown += delta.abs();
          _accUp = 0;
          if (_accDown >= settings.accMeters) {
            sounds.playAltitudeAlarm();
            _accDown = 0;
          }
        }
      }
    }

    // 4. C. Lògica de Cotes (cota)
    if (settings.cotaEnabled && settings.cotaMeters > 0) {
      int currentFloor = (_smoothedAlt / settings.cotaMeters).floor();

      if (_lastCotaFloor != null && currentFloor != _lastCotaFloor) {
        const double hysteresis = 5.0;
        double threshold = (currentFloor > _lastCotaFloor!)
            ? currentFloor * settings.cotaMeters
            : (currentFloor + 1) * settings.cotaMeters;

        if ((currentFloor > _lastCotaFloor! &&
                _smoothedAlt >= threshold + hysteresis) ||
            (currentFloor < _lastCotaFloor! &&
                _smoothedAlt <= threshold - hysteresis)) {
          sounds.playAltitudeAlarm();
          _lastCotaFloor = currentFloor;
        }
      } else {
        _lastCotaFloor = currentFloor;
      }
    }
  }

  void _emitProgress() {
    final s = rootRef.read(alarmSettingsProvider);

    // 🔍 PRINT 1: Comprovar si el motor sap que l'usuari vol alarmes
    print("--- EMIT PROGRESS ---");
    print(
      "Settings: Dist=${s.distanceEnabled}, Acc=${s.accEnabled}, Cota=${s.cotaEnabled}",
    );

    double distP = (s.distanceMeters > 0)
        ? (_distanceAccumulated / s.distanceMeters)
        : 0;
    double accP = (s.accMeters > 0) ? (max(_accUp, _accDown) / s.accMeters) : 0;
    double cotaP = (s.cotaMeters > 0)
        ? ((_smoothedAlt % s.cotaMeters) / s.cotaMeters)
        : 0;

    double timeP = 0;
    if (s.timeEnabled && _lastTimeAlarm != null) {
      final elapsed = DateTime.now().difference(_lastTimeAlarm!).inSeconds;
      timeP = (elapsed / s.timeSeconds);
    }

    // 🔍 PRINT 2: Veure els valors calculats abans de l'enviament
    print(
      "Calculated: DistP=${distP.toStringAsFixed(2)}, AccP=${accP.toStringAsFixed(2)}, TimeP=${timeP.toStringAsFixed(2)}",
    );

    _progressController.add(
      AlarmProgress(
        distance: distP.clamp(0.0, 1.0),
        accProgress: accP.clamp(0.0, 1.0),
        cotaProgress: cotaP.clamp(0.0, 1.0),
        time: timeP.clamp(0.0, 1.0),
      ),
    );
  }

  // Mantenim els teus mètodes de temps i distància sense canvis estructurals
  void _checkTimeAlarm() {
    final settings = rootRef.read(alarmSettingsProvider);
    if (!settings.timeEnabled) return;
    final now = DateTime.now();
    _lastTimeAlarm ??= now;
    if (now.difference(_lastTimeAlarm!).inSeconds >= settings.timeSeconds) {
      sounds.playTimeAlarm();
      _lastTimeAlarm = now;
    }
  }

  void _checkDistanceAlarm(LatLng pos, double threshold) {
    if (_lastPos == null) return;
    final step = _distanceBetween(_lastPos!, pos);
    if (step.isFinite && step > 2 && step < 50) {
      _distanceAccumulated += step;
      if (_distanceAccumulated >= threshold) {
        sounds.playDistanceAlarm();
        _distanceAccumulated = 0;
      }
    }
  }

  // El teu helper de distància original
  double _distanceBetween(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _deg(b.latitude - a.latitude);
    final dLon = _deg(b.longitude - a.longitude);
    final h =
        (1 - cos(dLat)) / 2 +
        cos(_deg(a.latitude)) * cos(_deg(b.latitude)) * (1 - cos(dLon)) / 2;
    return 2 * R * sqrt(h);
  }

  double _deg(double d) => d * pi / 180.0;

  final _progressController = StreamController<AlarmProgress>.broadcast();
  Stream<AlarmProgress> get progressStream => _progressController.stream;
}
