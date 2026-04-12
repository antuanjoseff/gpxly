import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/features/elevation_profile/elevation_profile_screen.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/screens/settings/gps_settings_screen.dart';
import 'package:gpxly/screens/stats_screen.dart';
import 'package:gpxly/services/recording_handler.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/ui/app_styles.dart';
import 'package:gpxly/ui/bottom_bar/bottom_bar_container.dart';
import 'package:gpxly/utils/color_extensions.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:gpxly/widgets/floating_route_panel.dart';
import 'package:gpxly/widgets/gps_accuracy_bars.dart';
import 'package:gpxly/widgets/import_gpx_button.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
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
    final prefs = await SharedPreferences.getInstance();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Finalitzar gravació"),
        content: const Text("Què vols fer amb la gravació actual?"),
        actions: [
          Row(
            children: [
              // BOTÓ COMPARTIR (icona) — ocupa menys espai
              Expanded(
                flex: 1, // 👈 més petit
                child: SizedBox(
                  height: 56, // 👈 mateixa alçada
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, "share"),
                    child: const Icon(Icons.share, size: 26),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // BOTÓ FINALITZAR (text) — ocupa més espai
              Expanded(
                flex: 2, // 👈 més ample
                child: SizedBox(
                  height: 56, // 👈 mateixa alçada
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, "finish"),
                    child: const Text(
                      "FINALITZAR",
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == null) return;

    // Aturem la gravació
    await ref.read(trackProvider.notifier).stopRecording();
    if (!context.mounted) return;

    if (result == "share") {
      await _shareTrack();
      return;
    }

    // Si ha triat FINALITZAR → mostrar diàleg de mantenir o eliminar
    final eliminar = await _askDeleteTrack();
    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);
      ref.read(trackProvider.notifier).reset();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }

  Future<bool?> _askDeleteTrack() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar dades?"),
        content: const Text("Vols eliminar la informació actual del track?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("MANTENIR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ELIMINAR"),
          ),
        ],
      ),
    );
  }

  void _preguntarNomesReset() async {
    final prefs = await SharedPreferences.getInstance();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Gestió del track"),
        content: const Text(
          "Vols mantenir els punts actuals o reiniciar per començar de zero?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              prefs.setBool("preserve_track_on_start", false);
              ref.read(trackProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text("REINICIAR"),
          ),
          ElevatedButton(
            style: AppButtons.dialog(AppColors.primary),
            onPressed: () {
              prefs.setBool("preserve_track_on_start", true);
              Navigator.pop(context);
            },
            child: const Text("MANTENIR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
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

    ref.listen(importedTrackProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

      if (next == null || next.coordinates.isEmpty) {
        mapController!.setGeoJsonSource("imported_track", {
          "type": "FeatureCollection",
          "features": [],
        });
        return;
      }

      mapController!.setGeoJsonSource("imported_track", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": next.coordinates},
          },
        ],
      });

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(next.minLat!, next.minLon!),
            northeast: LatLng(next.maxLat!, next.maxLon!),
          ),
          left: 40,
          top: 40,
          right: 40,
          bottom: 40,
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
                backgroundColor: AppColors.primary,
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
                  ImportGpxButton(mapController: mapController),
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
            : BottomBarContainer(
                isExpanded: _isPanelExpanded,
                onToggle: () =>
                    setState(() => _isPanelExpanded = !_isPanelExpanded),

                state: track.recordingState,

                onStart: () async {
                  await RecordingHandler.start(context, ref, mapController);
                  setState(() => _isPanelExpanded = false);
                },

                onPause: () => RecordingHandler.pause(ref),

                onResume: () => RecordingHandler.resume(ref),

                onStop: () => _handleStopProcess(context, ref),

                importButton: ImportGpxButton(mapController: mapController),
              ),
      ),
    );
  }

  Future<void> _forceSavePosition(double lat, double lon) async {
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

  Future<void> _shareTrack() async {
    final track = ref.read(trackProvider);
    if (track.coordinates.isEmpty) return;

    // 1. Exportar i compartir
    final filename = buildGpxFilename();
    await exportGpx(filename, ref, context);

    if (!mounted) return;

    // 2. Preguntar si vol eliminar o mantenir
    final prefs = await SharedPreferences.getInstance();
    final eliminar = await _askDeleteTrack();

    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);
      ref.read(trackProvider.notifier).reset();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }
}
