import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/screens/elevation_profile_screen.dart';
import 'package:gpxly/screens/settings/gps_settings_screen.dart';
import 'package:gpxly/screens/settings/tabs/track_settings_tab.dart';
import 'package:gpxly/screens/stats_screen.dart';
import 'package:gpxly/services/native_gps_channel.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/ui/app_styles.dart';
import 'package:gpxly/utils/color_extensions.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:gpxly/widgets/floating_route_panel.dart';
import 'package:gpxly/widgets/gps_accuracy_bars.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';

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
  LatLng? _initialCameraTarget;

  Timer? _cameraMoveDebounce;
  DateTime? _lastBackPress;
  DateTime? _lastSaveTime;

  StreamSubscription<Map<String, dynamic>>? _gpsSub;

  LatLng? _lastPosition;
  Timer? _animationTimer;

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

    _loadLastPosition();
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble("last_lat");
    final lon = prefs.getDouble("last_lon");

    if (lat != null && lon != null) {
      _initialCameraTarget = LatLng(lat, lon);
    } else {
      _initialCameraTarget = const LatLng(0, 0);
    }

    if (mounted) setState(() {});
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
        title: const Text("Finalitzar gravació?"),
        content: const Text(
          "Aquesta acció tancarà la ruta actual i ja no s’hi afegiran més punts.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL·LA"),
          ),
          ElevatedButton(
            style: AppButtons.dialog(Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("FINALITZA"),
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
          "Vols exportar o compartir el fitxer GPX d’aquesta activitat?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ARA NO"),
          ),
          ElevatedButton.icon(
            style: AppButtons.dialog(AppColors.tertiary),
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
        content: const Text(
          "Vols reiniciar el track per començar una nova gravació?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(trackProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text("REINICIAR (NETEJA)"),
          ),
          ElevatedButton(
            style: AppButtons.dialog(AppColors.primary),
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
    final trackSettings = ref.watch(trackSettingsProvider);

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
    ref.listen(trackSettingsProvider, (previous, next) {
      if (mapController == null || !styleInitialized) return;

      mapController!.setLayerProperties(
        "track_line_layer", // 👈 el teu layer del JSON
        LineLayerProperties(
          lineColor: next.color.toMapLibreColor(),
          lineWidth: next.width,
          lineCap: "round",
          lineJoin: "round",
        ),
      );
    });

    if (_initialCameraTarget == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

                      Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final acc = ref.watch(gpsAccuracyProvider);
                            if (acc == 999.0) return const SizedBox.shrink();
                            return Text(
                              "${acc.round()}m",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            );
                          },
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
            RepaintBoundary(
              child: MapLibreMap(
                trackCameraPosition: true,
                styleString: "assets/osm_style.json",
                initialCameraPosition: CameraPosition(
                  target: _initialCameraTarget!,
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
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

                  // Apliquem color i gruix del track triats per l’usuari
                  mapController!.setLayerProperties(
                    "track_line_layer",
                    LineLayerProperties(
                      lineColor: trackSettings.color.toMapLibreColor(),
                      lineWidth: trackSettings.width,
                      lineCap: "round",
                      lineJoin: "round",
                    ),
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
              ),
            ),

            if (!_fullScreen) ...[
              // -------------------------
              // PÍNDOLA FLOTANT (CENTRAT DALT)
              // -------------------------
              Positioned(
                top: 10, // Una mica més amunt
                left: 10, // Ancorat a l'esquerra
                child: FloatingRoutePanel(
                  isRecording: track.recordingState == RecordingState.recording,
                  duration: track.duration,
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
                          color: AppColors.tertiary,
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
                          color:
                              AppColors.tertiary, // Mateix fons que la píndola
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
                            color: AppColors.tertiary,
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
                    5,
                    16,
                    MediaQuery.of(context).padding.bottom + 5,
                  ),
                  decoration: BoxDecoration(
                    // Estil Gràfit amb transparència
                    color: AppColors.primary,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 45,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                            // ───────────────────────────────────────────────
                            // ESTAT 1 — IDLE → Botó INICIAR RUTA
                            // ───────────────────────────────────────────────
                            if (track.recordingState ==
                                RecordingState.idle) ...[
                              Expanded(
                                child: ElevatedButton.icon(
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
                              ),
                            ]
                            // ───────────────────────────────────────────────
                            // ESTAT 2 — RECORDING → Botó PAUSA (long press → menú)
                            // ───────────────────────────────────────────────
                            else if (track.recordingState ==
                                RecordingState.recording) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFFFFA000,
                                    ).withAlpha(180),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _pauseRecording,
                                  onLongPress: () {
                                    // 🔥 Ja no fem servir cap variable
                                    // Simplement passem a l’estat paused
                                    _pauseRecording();
                                  },
                                  icon: const Icon(Icons.pause),
                                  label: const Text(
                                    "PAUSA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                            // ───────────────────────────────────────────────
                            // ESTAT 3 — PAUSED → Botons REPRENDRE + FINALITZAR
                            // ───────────────────────────────────────────────
                            else if (track.recordingState ==
                                RecordingState.paused) ...[
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF2979FF,
                                    ).withAlpha(180),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _resumeRecording,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text(
                                    "REPRÈN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFFFF5252,
                                    ).withAlpha(180),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      58,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _handleStopProcess(context, ref),
                                  child: const Icon(Icons.stop, size: 26),
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

    // 1. Comprovar servei de localització
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;

      final activate = await AppMessages.showGpsDisabledDialog(context);
      if (activate == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    // 2. Comprovar permisos
    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permís necessari"),
        content: const Text(
          "Per poder gravar la ruta correctament, cal permetre "
          "l'accés a la ubicació en tot moment.\n\n"
          "A la pantalla següent, selecciona:\n\n"
          "👉  \"Permetre sempre\"",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL·LA"),
          ),
          ElevatedButton(
            style: AppButtons.dialog(Colors.blue), // o el color que vulguis
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CONTINUA"),
          ),
        ],
      ),
    );
    if (continuar != true) return;
    final ok = await PermissionsService.ensurePermissions(context);
    if (!context.mounted || !ok) return;

    // 🔥 NOU DIÀLEG: Explicar que cal seleccionar "Permetre sempre"

    ref.read(trackProvider.notifier).reset();
    // 3. Primer punt immediat
    final pos = await Geolocator.getCurrentPosition();

    final correctedAlt = ref
        .read(trackProvider.notifier)
        .localAltitudeCorrection(pos.latitude, pos.longitude);

    notifier.addCoordinate(
      pos.latitude,
      pos.longitude,
      pos.accuracy,
      correctedAlt,
    );

    // ref.read(gpsAccuracyProvider.notifier).state = pos.accuracy;
    // ref.read(gpsAltitudeProvider.notifier).state = pos.altitude;

    // 4. Iniciar el listener del TrackNotifier
    notifier.startRecording(context);

    // 5. Iniciar el servei natiu
    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );

    // 6. Centrar el mapa
    if (mapController != null) {
      isProgrammaticMove = true;
      mapController!
          .animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
          )
          .then((_) => isProgrammaticMove = false);
    }
  }

  Future<void> _pauseRecording() async {
    final notifier = ref.read(trackProvider.notifier);

    notifier.pauseRecording(); // Només pausa la lògica interna
    await NativeGpsChannel.stop(); // Atura el servei natiu
  }

  Future<void> _resumeRecording() async {
    final notifier = ref.read(trackProvider.notifier);

    notifier.resumeRecording(); // Treu la pausa

    final settings = ref.read(gpsSettingsProvider);
    await NativeGpsChannel.start(
      useTime: settings.useTime,
      seconds: settings.seconds,
      meters: settings.meters,
      accuracy: settings.accuracy,
    );
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

    // Obtenim l'estat actual del track per guardar l'última telemetria coneguda
    final track = ref.read(trackProvider);

    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lon', lon);

    // 🔹 Guardem les noves propietats de l'últim punt registrat
    if (track.altitudes.isNotEmpty) {
      await prefs.setDouble('last_alt', track.altitudes.last);
    }
    if (track.speeds.isNotEmpty) {
      await prefs.setDouble('last_speed', track.speeds.last);
    }
    if (track.headings.isNotEmpty) {
      await prefs.setDouble('last_heading', track.headings.last);
    }
    if (track.satellites.isNotEmpty) {
      await prefs.setInt('last_sat', track.satellites.last);
    }
    if (track.accuracies.isNotEmpty) {
      await prefs.setDouble('last_acc', track.accuracies.last);
    }
    if (track.vAccuracies.isNotEmpty) {
      await prefs.setDouble('last_vAcc', track.vAccuracies.last);
    }

    print(">>> Posició i telemetria completa guardada a SharedPreferences");
  }

  Future<LatLng> _getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('last_lat') ?? 41.3851;
    final lon = prefs.getDouble('last_lon') ?? 2.1734;

    // 🔹 Recuperem la resta de valors per si vols inicialitzar els providers de la UI
    final alt = 0.0;
    final acc = prefs.getDouble('last_acc') ?? 0.0;

    // Opcional: Podries actualitzar els teus providers de la UI aquí
    // per evitar que surtin a zero en obrir l'app:
    ref.read(gpsAltitudeProvider.notifier).state = alt;
    ref.read(gpsAccuracyProvider.notifier).state = acc;

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
