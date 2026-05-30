import 'dart:async'; // ✅ MANTINGUT / AFEGIT per al Timer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/core/altitude/altitude_processor.dart';
// Models immutables refactoritzats
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/notifiers/gps_bearing_notifier.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
// ✅ AFEGIT: Importem el proveïdor de la ruta per poder actualitzar el seu progrés visual
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/services/cog_service.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:senda/services/native_gps_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationNotifier extends Notifier<UserPosition?> {
  StreamSubscription? _gpsSub;
  bool gpsActive = false;
  bool _isSimulationRunning = false;
  bool _isSimulationPaused = false;

  // ─────────────────────────────────────────────────────────────
  // 🎮 LES DUES NOVES VARIABLES DE CLASSE REQUERIDES
  // ─────────────────────────────────────────────────────────────
  Timer? _simulationTimer; // Guarda el batec del Mock GPS d'1 segon [INDEX]
  int _currentSimulationIndex =
      0; // Custodia per quin punt del track anem caminant [INDEX]

  final _cogService = CogService();

  bool get isSimulationRunning => _isSimulationRunning;
  bool get isSimulationPaused => _isSimulationPaused;

  @override
  UserPosition? build() {
    ref.onDispose(() {
      _gpsSub?.cancel();
      _simulationTimer
          ?.cancel(); // Netegem també el temporitzador si es destrueix el giny [INDEX]
      _cogService.clearAllCacheFiles();
    });
    return null;
  }

  void toggleSimulationPause() {
    _isSimulationPaused = !_isSimulationPaused;
  }

  // 🛰️ HARDWARE: ENGEGADA I CONFIGURACIÓ SEGONS GPS_SETTINGS
  // Dins de lib/notifiers/location_notifier.dart
  Future<void> ensureGpsStarted() async {
    if (gpsActive) return;

    // 1. Engeguem els dos canals físics de maquinari de fons
    await NativeBarometerChannel.start();

    // 2. Esperem que les preferències de configuració estiguin llegides del disc
    await ref.read(gpsSettingsProvider.notifier).initialized;

    // 3. Executem l'apply() del teu GpsSettingsNotifier!
    // Això aplicarà de forma atòmica i immediata el període correcte en microsegons
    // (ja sigui 1s, 5s o 2s) al xip del baròmetre segons el mode triat [INDEX].
    await ref.read(gpsSettingsProvider.notifier).apply();

    // 4. Connectem el flux d'entrada que rebrà dades exactament a la freqüència del teu apply()
    NativeBarometerChannel.pressureStream().listen((hPa) {
      ref.read(altitudeProcessorProvider.notifier).updateBaro(hPa);
    });

    // 5. Connectem la subscripció sota els paràmetres del teu record d'origen
    final gpsSettings = ref.read(gpsSettingsProvider);
    _gpsSub?.cancel();
    _gpsSub = NativeGpsChannel.positionStream().listen((data) {
      _processIncomingGpsPoint(data);
    });

    gpsActive = true;
  }

  // 🎯 RECEPCIÓ, CORRECCIÓ D'ALTITUD I EMISSIÓ DEL MODEL
  void _processIncomingGpsPoint(Map<String, dynamic> data) async {
    final lat = data["lat"] as double;
    final lon = data["lon"] as double;
    final accuracy = data["accuracy"] as double;
    final altitude = data["altitude"] as double;
    final speed = data["speed"] as double;
    final heading = data["heading"] as double;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(data["timestamp"]);
    final vAccuracy = data["vAccuracy"] as double;
    final satellites = data["satellites"] as int? ?? 0;

    ref.read(gpsBearingProvider.notifier).update(heading);
    ref.read(gpsAccuracyProvider.notifier).update(accuracy);

    double finalAlt;
    bool finalIsFixed;

    if (_isSimulationRunning) {
      finalAlt = altitude;
      finalIsFixed = true;
    } else {
      final (correctedAlt, isFixed) = await _cogService.getCorrectedElevation(
        lat,
        lon,
        altitude,
      );
      finalAlt = correctedAlt;
      finalIsFixed = isFixed;

      // ─────────────────────────────────────────────────────────────
      // 🔥 CONEXIÓ DIRECTA AMB EL TEU ALTITUDE_PROCESSOR
      // ─────────────────────────────────────────────────────────────
      // Si el CogService ha pogut extreure i corregir l'altitud de la cel·la digital (isFixed == true),
      // li passem directament la cota de referència al teu motor analític de baròmetre.
      if (isFixed) {
        final processor = ref.read(altitudeProcessorProvider.notifier);
        processor.updateDem(correctedAlt);
        processor.process();
      }
      // Passem la velocitat del satèl·lit real perquè el baròmetre recalculi el seu període d'espera dinàmic [INDEX]
      ref.read(gpsSettingsProvider.notifier).updateBarometerSync(speed);
    }

    ref
        .read(gpsAltitudeProvider.notifier)
        .update(finalAlt, horizontalAccuracy: accuracy);

    state = UserPosition(
      position: LatLng(lat, lon),
      altitude: finalAlt,
      isHgtFixed: finalIsFixed,
      timestamp: timestamp,
      accuracy: accuracy,
      vAccuracy: vAccuracy,
      speed: speed,
      heading: heading,
      satellites: satellites,
      distanceAtPoint: 0.0,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🏃 MOTOR DE SIMULACIÓ AVANÇAT (MOCK GPS PROGRESSIU DEL GPX)
  // ─────────────────────────────────────────────────────────────
  void simulateImportedTrack(dynamic importedTrack) async {
    // 1. Validacions estructurals de seguretat
    if (importedTrack == null || importedTrack.points.isEmpty) return;
    if (_isSimulationRunning) return;

    print("🎮 [MOCK GPS] Iniciant simulació progressiva sobre el track...");

    _isSimulationRunning = true;
    _isSimulationPaused = false;
    _currentSimulationIndex = 0;

    // 2. Pausem temporalment el GPS real de maquinari per evitar col·lisions
    _gpsSub?.pause();
    gpsActive = true;

    // Cancel·lem qualsevol temporitzador residual per seguretat
    _simulationTimer?.cancel();

    // 3. Arrenquem el bucle de rellotge del Mock GPS (Emet un punt cada 1 segon)
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gpsActive) {
        timer.cancel();
        return;
      }

      // ⏸️ CONTROL DE PAUSA DE LA SIMULACIÓ
      if (_isSimulationPaused) return;

      // Si arribem al final dels punts del GPX, tanquem l'emulador
      if (_currentSimulationIndex >= importedTrack.points.length) {
        print("🎮 [MOCK GPS] Simulació finalitzada amb èxit (Fi de ruta).");
        timer.cancel();
        _endSimulation();
        return;
      }

      // 🔥 NOTIFIQUEM AL PROVEÏDOR DE LA RUTA QUIN ÉS L'ÍNDEX VISIBLE ARA MATEIX
      ref
          .read(importedTrackProvider.notifier)
          .updateSimulationProgress(_currentSimulationIndex);

      // 4. Extraiem el punt geomètric i d'altitud real del track guia importat
      final currentImportedPoint =
          importedTrack.points[_currentSimulationIndex];

      // Reconstruïm les dades com si vinguessin síncronament del canal natiu
      final Map<String, dynamic> mockData = {
        "lat": currentImportedPoint.position.latitude,
        "lon": currentImportedPoint.position.longitude,
        "altitude": currentImportedPoint.altitude,
        "accuracy": 3.0,
        "speed": currentImportedPoint.speed > 0.1
            ? currentImportedPoint.speed
            : 1.4, // 1.4 m/s ~ 5 km/h (pas humà)
        "heading": currentImportedPoint.heading,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "vAccuracy": 1.5,
        "satellites": currentImportedPoint.satellites > 0
            ? currentImportedPoint.satellites
            : 12,
      };

      // 5. Injectem la coordenada al processador del motor de localització
      _processIncomingGpsPoint(mockData);

      // Avancem l'índex per al següent batec de rellotge
      _currentSimulationIndex++;
    });
  }

  void _endSimulation() {
    _isSimulationRunning = false;
    _isSimulationPaused = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;

    // 🔥 Restaurem la línia completa (visibilitat total) en acabar la depuració
    ref.read(importedTrackProvider.notifier).resetSimulationProgress();

    if (_gpsSub != null) {
      _gpsSub!.resume();
    } else {
      gpsActive = false;
    }
  }

  void stopGps() {
    _simulationTimer?.cancel(); // Netegem el timer si s'atura globalment
    _simulationTimer = null;
    _isSimulationRunning = false;
    _isSimulationPaused = false;

    NativeGpsChannel.stop();
    _gpsSub?.cancel();
    _gpsSub = null;
    gpsActive = false;
    state = null;
  }

  // ─── 💾 PERSISTÈNCIA A DISC: GUARDAR COORDENADES AL SORTIR ───
  Future<void> saveCurrentPositionToPrefs() async {
    final currentPos = state;
    // Només guardem si tenim una coordenada vàlida a la pantalla
    if (currentPos == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("last_lat", currentPos.position.latitude);
    await prefs.setDouble("last_lon", currentPos.position.longitude);
    print(
      "💾 [PERSISTÈNCIA] Coordenades de sortida guardades amb èxit: ${currentPos.position}",
    );
  }

  // ─── 🔄 PERSISTÈNCIA A DISC: LLEGIR COORDENADES AL ARRENCAR ───
  Future<void> loadCachePositionFromPrefs() async {
    // Si el GPS real de maquinari ja ha emès un punt abans de carregar el disc, la caché ja no cal
    if (state != null) return;

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble("last_lat");
    final lon = prefs.getDouble("last_lon");

    if (lat != null && lon != null && state == null) {
      print(
        "🔄 [PERSISTÈNCIA] Carregant posició estàtica de caché: $lat, $lon",
      );

      // Injectem l'estat temporal amb precisió 999m de referència de fons [INDEX]
      state = UserPosition(
        position: LatLng(lat, lon),
        altitude: 0.0,
        isHgtFixed: false,
        timestamp: DateTime.now(),
        accuracy: 999.0,
        vAccuracy: 0.0,
        speed: 0.0,
        heading: 0.0,
        satellites: 0,
        distanceAtPoint: 0.0,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 🔗 EL PROVEÏDOR GLOBAL DE LOCALITZACIÓ DE RIVERPOD
// ─────────────────────────────────────────────────────────────
final locationProvider = NotifierProvider<LocationNotifier, UserPosition?>(() {
  return LocationNotifier();
});
