import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// Models immutables refactoritzats
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
// Telemetria existent per a la interfície visual de les barres i indicadors
import 'package:senda/notifiers/gps_bearing_notifier.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/services/cog_service.dart';
// Canals natius i serveis de l'aplicació
import 'package:senda/services/native_gps_channel.dart';

class LocationNotifier extends Notifier<UserPosition?> {
  StreamSubscription? _gpsSub;
  bool gpsActive = false;
  bool _isSimulationRunning = false;
  bool _isSimulationPaused = false;

  final _cogService = CogService();

  bool get isSimulationRunning => _isSimulationRunning;
  bool get isSimulationPaused => _isSimulationPaused;

  @override
  UserPosition? build() {
    ref.onDispose(() {
      _gpsSub?.cancel();
      _cogService.dispose();
    });
    return null; // Inicialment no hi ha posició GPS fins que s'engegui
  }

  void toggleSimulationPause() {
    _isSimulationPaused = !_isSimulationPaused;
  }

  // 🛰️ HARDWARE: ENGEGADA I CONFIGURACIÓ SEGONS GPS_SETTINGS
  Future<void> ensureGpsStarted() async {
    if (gpsActive) return;

    // 1. Esperem que les preferències de l'usuari estiguin inicialitzades
    await ref.read(gpsSettingsProvider.notifier).initialized;
    final gpsSettings = ref.read(gpsSettingsProvider);

    // 2. Passem els paràmetres (useTime, seconds, meters, accuracy) al motor natiu [INDEX]
    await NativeGpsChannel.start(
      useTime: gpsSettings.useTime,
      seconds: gpsSettings.seconds,
      meters: gpsSettings.meters,
      accuracy: gpsSettings.accuracy,
    );

    // 3. Ens subscrivim al flux que ja ens arriba completament filtrat pel propi OS [INDEX]
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

    // 1. Informem els indicadors de telemetria visual existents de l'app (AppBar/Brúixola)
    ref.read(gpsBearingProvider.notifier).update(heading);
    ref.read(gpsAccuracyProvider.notifier).update(accuracy);

    // 2. CORRECCIÓ D'ALTITUD (Síncrona en simulació, asíncrona real mitjançant DEM/Baròmetre) [INDEX]
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
    }

    // 3. Notifiquem el teu proveïdor d'altitud existent per mantenir la barra d'estat
    ref
        .read(gpsAltitudeProvider.notifier)
        .update(finalAlt, horizontalAccuracy: accuracy);

    // 4. 🔥 EMETEM EL NOU MODEL COMPLETAMENT IMMUTABLE CAP A TOTA L'APP
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
      distanceAtPoint:
          0.0, // Ho calcularà el RecordingNotifier si s'enregistra [INDEX]
    );
  }

  // 🏃 SIMULACIÓ REUBICADA (Bypass del GPS de fons) [INDEX]
  void simulateImportedTrack(dynamic importedTrack) async {
    if (importedTrack == null || importedTrack.coordinates.isEmpty) return;
    if (_isSimulationRunning) return;

    _isSimulationRunning = true;
    _isSimulationPaused = false;

    _gpsSub?.pause();
    gpsActive = true;

    for (int i = 0; i < importedTrack.coordinates.length; i++) {
      if (!gpsActive) break;

      while (_isSimulationPaused && gpsActive) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final coords = importedTrack.coordinates[i];
      final alt = importedTrack.altitudes[i];

      final mockData = {
        "lat": coords[1],
        "lon": coords[0],
        "altitude": alt,
        "accuracy": 5.0,
        "speed": 1.5,
        "heading": 0.0,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "vAccuracy": 2.0,
        "satellites": 10,
      };

      _processIncomingGpsPoint(mockData);

      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isSimulationRunning = false;
    _isSimulationPaused = false;

    if (_gpsSub != null) {
      _gpsSub!.resume();
    } else {
      gpsActive = false;
    }
  }

  void stopGps() {
    NativeGpsChannel.stop(); // Aturem també la petició de maquinari a baix nivell [INDEX]
    _gpsSub?.cancel();
    _gpsSub = null;
    gpsActive = false;
    state =
        null; // Deixem l'estat en null per indicar que s'ha apagat el sensor [INDEX]
  }
}

// 🔗 EL PROVEÏDOR GLOBAL DE LOCALITZACIÓ DE RIVERPOD
final locationProvider = NotifierProvider<LocationNotifier, UserPosition?>(() {
  return LocationNotifier();
});
