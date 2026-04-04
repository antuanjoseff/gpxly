import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gps_settings_provider.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/screens/elevation_profile_screen.dart';
import 'package:gpxly/screens/gps_settings_screen.dart';
import 'package:gpxly/screens/stats_screen.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:gpxly/widgets/floating_route_panel.dart';
import 'package:gpxly/widgets/gps_accuracy_bars.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/notifiers/gps_accuracy_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapLibreMapController? mapController;
  bool styleInitialized = false;
  bool userMovedMap = false;
  bool isProgrammaticMove = false;
  bool _isPanelExpanded = true;
  bool _fullScreen = false;

  Timer? _cameraMoveDebounce;
  DateTime? _lastBackPress;
  DateTime? _lastSaveTime;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  LatLng? _lastPosition;
  Timer? _animationTimer;

  // -------------------------------
  // SIMULADOR PUNTS DE TRACK
  // -------------------------------

  Timer? _simulationTimer;
  double _simLat = 41.3850;
  double _simLon = 2.1734;
  double _simAlt = 100.0;
  int _tick = 0;

  void _toggleSimulation() {
    if (_simulationTimer != null && _simulationTimer!.isActive) {
      _simulationTimer!.cancel();
      return;
    }

    // Reiniciem variables per a una ruta neta
    _simLat = 41.3850;
    _simLon = 2.1734;
    int tick = 0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tick++;

      // Moviment lineal constant (diagonal) per evitar oscil·lacions
      _simLat += 0.0002;
      _simLon += 0.0001;

      // Perfil d'alçada: Una pujada constant fins als 30 segons i després baixa
      double simulatedAlt = 100 + (tick < 30 ? tick * 5 : (60 - tick) * 5);

      // IMPORTANT: Enviem el timestamp com a quart element
      final double timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();

      ref.read(gpsAltitudeProvider.notifier).state = simulatedAlt;

      // Passem la llista completa al notifier
      ref
          .read(trackProvider.notifier)
          .addCoordinate(
            _simLat,
            _simLon,
            7.0,
            simulatedAlt,
            // <--- ASSEGURA'T QUE EL TEU addPoint ACCEPTA AIXÒ
          );
    });
  }

  // -------------------------------
  // FI DEL SIMULADOR
  // -------------------------------
  final ButtonStyle recordButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.all(16),
    elevation: 6,
  );

  final TextStyle recordLabelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final track = ref.read(trackProvider);
      if (track.coordinates.isNotEmpty) {
        final last = track.coordinates.last;
        // Aquí cridem a la funció que NO té filtre de temps
        _forceSavePosition(last[1], last[0]);
      }
    }
  }

  void _onMapChanged() {
    if (isProgrammaticMove) return; // 👈 CLAU

    final moving = mapController?.isCameraMoving ?? false;

    if (moving) {
      _cameraMoveDebounce?.cancel();
      _cameraMoveDebounce = Timer(const Duration(milliseconds: 150), () {
        userMovedMap = true;
      });
    }
  }

  void _handleStopProcess(BuildContext context, WidgetRef ref) async {
    // PAS 1: Confirmar aturada
    final volAturar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aturar ruta?"),
        content: const Text("Es deixarà de gravar la teva posició."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL·LA"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ATURA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (volAturar != true) return;

    // Aturem la gravació al teu provider
    await ref.read(trackProvider.notifier).stopRecording();

    if (!context.mounted) return;

    // PAS 2: Preguntar si es vol compartir
    final volCompartir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ruta finalitzada"),
        content: const Text(
          "Vols compartir el fitxer GPX d'aquesta activitat?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ARA NO"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.share),
            label: const Text("COMPARTIR"),
          ),
        ],
      ),
    );

    if (volCompartir == true) {
      // Si vol compartir, cridem a la teva funció que ja ho fa tot
      // (exporta, comparteix i pregunta pel reset)
      await _shareTrack();
    } else {
      // Si NO vol compartir, hem de preguntar igualment si vol fer el Reset
      // ja que la teva funció _shareTrack no s'executarà.
      _preguntarNomesReset();
    }
  }

  void _preguntarNomesReset() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Gestió del track"),
        content: const Text("Vols netejar el mapa per a una nova ruta?"),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(trackProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text("REINICIAR (NETEJA)"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("MANTENIR DADES"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);
    final altitude = ref.watch(gpsAltitudeProvider);

    // Listener dins build (Riverpod obliga)
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;
      if (next.coordinates.isEmpty) return;

      final last = next.coordinates.last;
      final lon = last[0];
      final lat = last[1];

      // 🔵 PRIMERA COORDENADA → dibuix immediat
      if (next.coordinates.length == 1) {
        updateMapPosition(mapController!, lat, lon, userMovedMap, (val) {
          if (mounted) setState(() => isProgrammaticMove = val);
        });

        // També cal dibuixar la línia (buida o amb 1 punt)
        mapController!.setGeoJsonSource("track_line", {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": next.coordinates,
              },
            },
          ],
        });

        return;
      }

      try {
        animateLastSegment(
          lat: lat,
          lon: lon,
          allCoordinates: next.coordinates,
          controller: mapController!,
          userMovedMap: userMovedMap,
          currentLastPosition: _lastPosition,
          currentTimer: _animationTimer,
          setLastPosition: (p) => _lastPosition = p,
          setTimer: (t) => _animationTimer = t,
          onAnimate: (val) {
            // <--- AFEGEIX AIXÒ
            if (mounted) setState(() => isProgrammaticMove = val);
          },
        );
      } catch (_) {}
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;

          AppMessages.showExitWarning(context);
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: true,
        appBar: _fullScreen
            ? null
            : AppBar(
                centerTitle: false,
                backgroundColor: Colors.black,
                automaticallyImplyLeading: false,
                titleSpacing: 16,

                // ESQUERRA: Identitat
                title: const Text(
                  'GpxGo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),

                // DRETA: Info GPS i Settings (Ara tot junt aquí)
                actions: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const GpsAccuracyBars(),
                      const SizedBox(width: 4),
                      if (accuracy != 999)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Text(
                            "${accuracy.round()}m",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GpsSettingsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        body: Stack(
          children: [
            FutureBuilder(
              future: _getLastPosition(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                return MapLibreMap(
                  trackCameraPosition: true,
                  styleString: "assets/osm_style.json",
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 14,
                  ),
                  onMapLongClick: (point, latlng) {
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.immersiveSticky,
                    );
                    setState(() => _fullScreen = true);
                  },
                  onMapClick: (point, latlng) {
                    if (!_fullScreen) return;
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                    setState(() => _fullScreen = false);
                  },

                  onCameraMove: (position) {
                    if (isProgrammaticMove) return;
                    userMovedMap = true;
                  },
                  onMapCreated: (controller) {
                    mapController = controller;
                    controller.addListener(_onMapChanged);
                  },
                  onStyleLoadedCallback: () async {
                    await setupUserLocationLayer(mapController!);
                    styleInitialized = true;

                    final prefs = await SharedPreferences.getInstance();
                    final lat = prefs.getDouble("last_lat");
                    final lon = prefs.getDouble("last_lon");

                    if (lat != null && lon != null) {
                      print("PROGRAMMATIC MOVE → animateCamera()");
                      isProgrammaticMove = true;
                      mapController!
                          .animateCamera(
                            CameraUpdate.newLatLng(LatLng(lat, lon)),
                          )
                          .then((_) => isProgrammaticMove = false);
                    }

                    updateMapPosition(
                      mapController!,
                      lat ?? 0,
                      lon ?? 0,
                      userMovedMap,
                      (val) {
                        if (mounted) setState(() => isProgrammaticMove = val);
                      },
                    );

                    final track = ref.read(trackProvider);

                    if (track.coordinates.isNotEmpty) {
                      final last = track.coordinates.last;

                      updateMapPosition(
                        mapController!,
                        last[1],
                        last[0],
                        userMovedMap,
                        (val) {
                          if (mounted) setState(() => isProgrammaticMove = val);
                        },
                      );

                      mapController!.setGeoJsonSource("track_line", {
                        "type": "FeatureCollection",
                        "features": [
                          {
                            "type": "Feature",
                            "geometry": {
                              "type": "LineString",
                              "coordinates": track.coordinates,
                            },
                          },
                        ],
                      });
                    }
                  },
                );
              },
            ),

            if (!_fullScreen) ...[
              // -------------------------
              // PÍNDOLA FLOTANT (CENTRAT DALT)
              // -------------------------
              Positioned(
                top: 10, // Una mica més amunt
                left: 10, // Ancorat a l'esquerra
                child: FloatingRoutePanel(
                  isRecording: track.recording,
                  duration: track.duration,
                  altitude: altitude,
                ),
              ),

              // -------------------------
              // COLUMNA DE BOTONS SUPERIOR DRETA
              // -------------------------
              Positioned(
                top: 10,
                right: 12,
                child: Column(
                  children: [
                    // // BOTÓ DE TEST (SIMULACIÓ)
                    // GestureDetector(
                    //   onTap: _toggleSimulation,
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: Colors.red.withAlpha(
                    //         150,
                    //       ), // Vermell per saber que és de test
                    //       borderRadius: BorderRadius.circular(8),
                    //       border: Border.all(color: Colors.white24),
                    //     ),
                    //     child: const Icon(
                    //       Icons
                    //           .bug_report_outlined, // Icona de "bicho" per debug
                    //       color: Colors.white,
                    //       size: 20,
                    //     ),
                    //   ),
                    // ),
                    // NOU: BOTÓ DE PERFIL D'ELEVACIÓ
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ElevationProfileScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(
                          Icons.terrain_outlined, // Icona de muntanya/relleu
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // BOTÓ DE DADES (ESTADÍSTIQUES)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackStatsScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(
                            180,
                          ), // Mateix fons que la píndola
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // BOTÓ DE CENTRAR MAPA
                    if (userMovedMap)
                      GestureDetector(
                        onTap: () {
                          final track = ref.read(trackProvider);
                          if (track.coordinates.isEmpty) return;
                          final last = track.coordinates.last;

                          setState(() {
                            userMovedMap = false;
                            isProgrammaticMove = true;
                          });

                          mapController
                              ?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(last[1], last[0]),
                                ),
                              )
                              .then((_) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (mounted)
                                      setState(
                                        () => isProgrammaticMove = false,
                                      );
                                  },
                                );
                              });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Icon(
                            Icons.gps_fixed, // O Icons.my_location
                            color: Colors
                                .white, // Blau per destacar que cal centrar
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _fullScreen
            ? null
            : SafeArea(
                bottom: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    // Estil Gràfit amb transparència
                    color: const Color(0xFF1A1A1A).withAlpha(200),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nansa per obrir/tancar (Més discreta)
                      GestureDetector(
                        onTap: () => setState(
                          () => _isPanelExpanded = !_isPanelExpanded,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Container(
                              width: 45,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_isPanelExpanded) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // ESTAT 1: NO GRAVANT (Botó Únic d'Inici)
                            if (!track.recording)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF00E676,
                                    ).withAlpha(180), // Verd Neó
                                    foregroundColor: Colors
                                        .black, // Contrast alt per al verd
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ), // Alçada fixa
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    _startRecording();
                                    setState(() => _isPanelExpanded = false);
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 28),
                                  label: const Text(
                                    "INICIA RUTA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              )
                            // ESTAT 2: GRAVANT
                            else ...[
                              // Botó de Pausa o Reprèn
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: track.paused
                                        ? const Color(0xFF2979FF).withAlpha(
                                            180,
                                          ) // Blau Elèctric
                                        : const Color(
                                            0xFFFFA000,
                                          ).withAlpha(180), // Ambre (Pausa)
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ), // 👈 ALÇADA FIXA
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => track.paused
                                      ? _resumeRecording()
                                      : _pauseRecording(),
                                  icon: Icon(
                                    track.paused
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                  label: Text(
                                    track.paused ? "REPRÈN" : "PAUSA",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Botó d'Aturar o Compartir
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: track.paused
                                        ? const Color(0xFF455A64).withAlpha(
                                            180,
                                          ) // Gris fosc (Compartir)
                                        : const Color(
                                            0xFFFF5252,
                                          ).withAlpha(180), // Vermell (Aturar)
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ), // 👈 MATEIXA ALÇADA FIXA
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onLongPress: () =>
                                      _handleStopProcess(context, ref),
                                  onPressed: () {
                                    if (track.paused) {
                                      _shareTrack();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Mantén premut per ATURAR",
                                          ),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    track.paused ? Icons.share : Icons.stop,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // -------------------------
  // FUNCIONS DE GRAVACIÓ
  // -------------------------

  Future<void> _startRecording() async {
    final notifier = ref.read(trackProvider.notifier);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;

      final activate = await AppMessages.showGpsDisabledDialog(context);
      if (activate == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    final ok = await PermissionsService.ensurePermissions(context);
    if (!context.mounted || !ok) return;
    print("GPXLY START RECORDING");

    final pos = await Geolocator.getCurrentPosition();
    notifier.addCoordinate(
      pos.latitude,
      pos.longitude,
      pos.accuracy,
      pos.altitude,
    );
    ref.read(gpsAccuracyProvider.notifier).state = pos.accuracy;
    ref.read(gpsAltitudeProvider.notifier).state = pos.altitude;

    _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
      double lat = data['lat'] as double;
      double lon = data['lon'] as double;
      double acc = data['accuracy'] as double;
      double altitude = data['altitude'] as double;
      // lat += randomOffset(50);
      // lon += randomOffset(50);

      notifier.addCoordinate(lat, lon, acc, altitude);
      ref.read(gpsAccuracyProvider.notifier).state = acc;
      ref.read(gpsAltitudeProvider.notifier).state = altitude.toDouble();
    });

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    if (mapController != null) {
      isProgrammaticMove = true;
      mapController!
          .animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
          )
          .then((_) => isProgrammaticMove = false);
    }

    notifier.startRecording(context);
  }

  Future<void> _pauseRecording() async {
    final notifier = ref.read(trackProvider.notifier);
    notifier.pauseRecording();
    await NativeGpsChannel.stop();
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<void> _resumeRecording() async {
    final notifier = ref.read(trackProvider.notifier);
    notifier.resumeRecording();

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    _gpsSub ??= NativeGpsChannel.positionStream().listen((data) {
      double lat = data['lat'] as double;
      double lon = data['lon'] as double;
      double acc = data['accuracy'] as double;
      double altitude = data['altitude'] as double;

      notifier.addCoordinate(lat, lon, acc, altitude);
      ref.read(gpsAccuracyProvider.notifier).state = acc;
      ref.read(gpsAltitudeProvider.notifier).state = altitude.toDouble();
    });
  }

  // Future<void> _stopRecording() async {
  //   final notifier = ref.read(trackProvider.notifier);

  //   notifier.stopRecording();
  //   await NativeGpsChannel.stop();
  //   await _gpsSub?.cancel();
  //   _gpsSub = null;

  //   final export = await AppMessages.showExportDialog(context);

  //   if (export == true) {
  //     final filename = buildGpxFilename();
  //     await exportGpx(filename, ref, context);
  //   }
  // }

  // // Funció amb filtre de 5 minuts
  // void _saveLastPosition(double lat, double lon) async {
  //   final now = DateTime.now();

  //   // Filtre de 5 minuts (300 segons)
  //   if (_lastSaveTime == null ||
  //       now.difference(_lastSaveTime!) > const Duration(minutes: 5)) {
  //     _forceSavePosition(lat, lon);
  //   }
  // }

  Future<void> _forceSavePosition(double lat, double lon) async {
    _lastSaveTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lon', lon);
    print(">>> Posició guardada (Debounce 5 min)");
  }

  Future<LatLng> _getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat =
        prefs.getDouble('last_lat') ?? 41.3851; // Valor per defecte (ex: BCN)
    final lon = prefs.getDouble('last_lon') ?? 2.1734;
    return LatLng(lat, lon);
  }

  Future<void> _shareTrack() async {
    final track = ref.read(trackProvider);

    if (track.coordinates.isEmpty) return;

    // Exporta i comparteix amb la funció que ja tens
    final filename = buildGpxFilename();
    await exportGpx(filename, ref, context);

    if (!mounted) return;

    // Diàleg després de compartir
    final reset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vols reiniciar el track?"),
        content: const Text(
          "Si continues, el track seguirà sumant punts.\n"
          "Si reinicies, s'esborrarà tota la informació actual.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Continuar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reiniciar"),
          ),
        ],
      ),
    );

    if (reset == true) {
      ref.read(trackProvider.notifier).reset();
      setState(() {});
    } else {
      setState(() {});
    }
  }
}
