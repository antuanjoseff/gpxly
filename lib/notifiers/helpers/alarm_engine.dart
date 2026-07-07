import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/alarm_progress.dart';
// ✅ ADAPTAT: Importem el nou canal de geolocalització atòmic
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/notifiers/helpers/track_sounds.dart';
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1: Hardware i dades netes

class AlarmEngine {
  final Ref rootRef;

  ProviderSubscription<UserPosition?>?
  _locationSub; // ✅ ADAPTAT: Canvi de StreamSubscription a Riverpod Subscription
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
  double? _baseCotaAlt;

  // Temps
  DateTime? _lastTimeAlarm;

  final TrackSounds sounds = TrackSounds();

  AlarmEngine(this.rootRef);

  // ───────────────────────────────────────────────
  // PUBLIC API
  // ───────────────────────────────────────────────

  Future<void> start() async {
    print("🚀 AlarmEngine START");

    _resetInternalState();

    _locationSub = rootRef.listen<UserPosition?>(locationProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      _onUserPositionIncoming(
        next,
      ); // Crida la teva funció de processament amb el nou model
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeAlarm();
      _emitProgress();
    });
  }

  void stop() {
    print("🚀 AlarmEngine STOP");
    _locationSub?.close(); // ✅ ADAPTAT: Tanquem la subscripció de Riverpod
    _locationSub = null;
    _timer?.cancel();
    _timer = null;
    _resetInternalState();
  }

  // ✅ ADAPTAT: Adaptat per rebre la nova estructura atòmica d'usuari de la branca
  void _onUserPositionIncoming(UserPosition userGps) {
    final pos = userGps.position;
    final settings = rootRef.read(alarmSettingsProvider);
    final gpsAltitude = rootRef.read(gpsAltitudeProvider);

    if (settings.distanceEnabled) {
      _checkDistanceAlarm(pos, settings.distanceMeters);
    }

    if (gpsAltitude > 0.1) {
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
    double altAnterior = _smoothedAlt;

    if (_smoothedAlt < 0) {
      _smoothedAlt = currentAlt;
      _baseCotaAlt = currentAlt; // Necessari per al progrés net de la cota
      return;
    } else {
      const double alpha = 0.15;
      _smoothedAlt = (_smoothedAlt * (1 - alpha)) + (currentAlt * alpha);
    }

    // 1️⃣ LÒGICA: DESNIVELL ACUMULAT (Corregit: independent i sense llindar alt)
    if (settings.accEnabled && settings.accMeters > 0) {
      double delta = _smoothedAlt - altAnterior;

      // Llindar molt baix (0.05) perquè el filtre alpha ja neteja el soroll
      if (delta.abs() > 0.05) {
        if (delta > 0) {
          _accUp += delta; // Sumem a la pujada
          // ✅ ELIMINAT: _accDown = 0; (Ja no esborrem el passat)
          if (_accUp >= settings.accMeters) {
            sounds.playAccumulatedAlarm();
            _accUp = 0;
          }
        } else {
          _accDown += delta.abs(); // Sumem a la baixada
          // ✅ ELIMINAT: _accUp = 0; (Ja no esborrem el passat)
          if (_accDown >= settings.accMeters) {
            sounds.playAccumulatedAlarm();
            _accDown = 0;
          }
        }
      }
    } else {
      // Si l'alarma s'apaga des de la pantalla, netegem els comptadors
      _accUp = 0;
      _accDown = 0;
    }

    // 2️⃣ LÒGICA: COTES ABSOLUTES (Corregit: histèresi real i independent)
    if (settings.cotaEnabled && settings.cotaMeters > 0) {
      int currentFloor = (_smoothedAlt / settings.cotaMeters).floor();

      if (_lastCotaFloor == null) {
        _lastCotaFloor = currentFloor;
        _baseCotaAlt = currentFloor * settings.cotaMeters.toDouble();
      } else if (currentFloor != _lastCotaFloor) {
        const double hysteresis = 4.0; // 4-5 metres de marge de seguretat

        double threshold = (currentFloor > _lastCotaFloor!)
            ? currentFloor * settings.cotaMeters
            : (currentFloor + 1) * settings.cotaMeters;

        bool crossUp =
            currentFloor > _lastCotaFloor! &&
            _smoothedAlt >= (threshold + hysteresis);
        bool crossDown =
            currentFloor < _lastCotaFloor! &&
            _smoothedAlt <= (threshold - hysteresis);

        if (crossUp || crossDown) {
          sounds.playCotaAlarm();
          _lastCotaFloor = currentFloor;
          _baseCotaAlt =
              currentFloor *
              settings.cotaMeters.toDouble(); // Actualitzem la base per a la UI
        }
        // ✅ CORREGIT: Hem eliminat el 'else' erroni d'aquí que trencava la histèresi!
      }
    } else {
      // Si l'alarma s'apaga, netegem l'estat de les cotes
      _lastCotaFloor = null;
      _baseCotaAlt = null;
    }
  }

  void _emitProgress() {
    final s = rootRef.read(alarmSettingsProvider);

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
