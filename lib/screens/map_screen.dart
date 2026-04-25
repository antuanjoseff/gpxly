import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/features/elevation_profile/elevation_profile_screen.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/gps_speed_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_settings_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/screens/settings/settings_screen.dart';
import 'package:gpxly/screens/stats_screen.dart';
import 'package:gpxly/screens/ux_google2.dart'
    show RecordingFollowingSimulatorPage;
import 'package:gpxly/services/gps_manager.dart';
import 'package:gpxly/services/gpx_import_flow.dart';
import 'package:gpxly/services/location_permission_flow.dart';
import 'package:gpxly/services/recording_handler.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/ui/bottom_bar/bottom_bar_container.dart';
import 'package:gpxly/utils/color_extensions.dart';
import 'package:gpxly/utils/map_animation.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:gpxly/widgets/compass_widget.dart';
import 'package:gpxly/widgets/gps_accuracy_bars.dart';

import 'package:gpxly/widgets/recording_status_bar.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  double _initialZoom = 14;
  bool isAnimatingSegment = false;
  Timer? _cameraMoveDebounce;
  DateTime? _lastBackPress;

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
    Future.microtask(
      () => ref.read(permissionsProvider.notifier).checkPermissions(),
    );
  }

  Future<void> _onFollowTrack() async {
    final notifier = ref.read(trackFollowNotifierProvider.notifier);
    final state = ref.read(trackFollowNotifierProvider);

    if (state.isFollowing) {
      // Si ja està seguint → ATURA SEGUIMENT
      notifier.stopFollowing();
      return;
    }

    // Si NO està seguint → activar GPS + centrar mapa + iniciar seguiment
    await notifier.startFollowingWithoutRecording(context, ref, mapController);
  }

  void _handleFollowTrack() {
    final importedTrack = ref.read(importedTrackProvider);
    if (importedTrack == null || importedTrack.coordinates.isEmpty) return;

    final coords = importedTrack.coordinates;
    final last = coords.last;

    setState(() {
      userMovedMap = false;
      isProgrammaticMove = true;
    });

    mapController
        ?.animateCamera(CameraUpdate.newLatLng(LatLng(last[1], last[0])))
        .then((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => isProgrammaticMove = false);
            }
          });
        });
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble("last_lat");
    final lon = prefs.getDouble("last_lon");

    if (lat != null && lon != null) {
      _initialCameraTarget = LatLng(lat, lon);
    } else {
      _initialCameraTarget = const LatLng(0, 0);
      _initialZoom = 1.0;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
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
    // Si la animación o la cámara están trabajando, ignoramos el evento
    if (isProgrammaticMove || isAnimatingSegment) return;

    final moving = mapController?.isCameraMoving ?? false;
    if (moving) {
      userMovedMap = true; // El usuario ha tomado el control manual
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

  bool isConsistentlyIncreasing(List<double> values) {
    for (int i = 1; i < values.length; i++) {
      if (values[i] < values[i - 1]) return false;
    }
    return true;
  }

  void _animateGpsPosition(LatLng newPos) {
    setState(() => isProgrammaticMove = true);

    final isRecording =
        ref.read(trackProvider).recordingState == RecordingState.recording;
    final shouldDrawSegment = isRecording;

    animateLastSegment(
      lat: newPos.latitude,
      lon: newPos.longitude,
      allCoordinates: ref.read(trackProvider).coordinates,
      controller: mapController!,
      userMovedMap: userMovedMap,
      currentLastPosition: _lastPosition,
      currentTimer: _animationTimer,
      setLastPosition: (p) => _lastPosition = p,
      setTimer: (t) => _animationTimer = t,
      onAnimate: (isAnimating) {
        if (mounted) setState(() => isProgrammaticMove = isAnimating);
      },
      overrideDrawPoint: null,
      overrideDrawLine: null,
      drawSegment: shouldDrawSegment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final trackSettings = ref.watch(trackSettingsProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final hasImportedTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;
    final trackFollowState = ref.watch(trackFollowNotifierProvider);

    // Listener dins build (Riverpod obliga)
    // 1. LISTENER DEL GPS (El que manda)
    ref.listen(gpsManagerProvider, (prev, next) {
      if (!styleInitialized || mapController == null || next.position == null)
        return;

      // Solo disparamos la animación.
      // Ella internamente ya sabe si debe centrar la cámara (if !userMovedMap)
      _animateGpsPosition(next.position!);
    });

    // 2. LISTENER DEL TRACK (El pasivo)
    // Este código debe estar justo debajo del anterior en tu build
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;

      // 1) Si el track se ha reseteado → limpiamos
      if (next.coordinates.isEmpty) {
        mapController!.setGeoJsonSource("track_line", {
          "type": "FeatureCollection",
          "features": [],
        });
        return;
      }

      // 2) PREVENIR EL "EFECTO FLASH"
      // Si estamos grabando, preparamos una lista que NO tenga el último punto,
      // ya que ese punto es el "destino" que la animación va a alcanzar poco a poco.
      List<List<double>> coordinatesToDraw = next.coordinates;

      bool isRecording = next.recordingState == RecordingState.recording;
      if (isRecording && next.coordinates.length > 1) {
        coordinatesToDraw = next.coordinates.sublist(
          0,
          next.coordinates.length - 1,
        );
      }

      // 3) Solo dibujamos si NO estamos animando.
      // Cuando la animación termine (isAnimatingSegment = false), este listener
      // se disparará de nuevo y dibujará la línea completa definitiva.
      if (!isAnimatingSegment) {
        mapController!.setGeoJsonSource("track_line", {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": coordinatesToDraw,
              },
            },
          ],
        });
      }
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

      final importedSettings = ref.read(importedTrackSettingsProvider);

      mapController!.setLayerProperties(
        "imported_track_layer",
        LineLayerProperties(
          lineColor: importedSettings.color.toMapLibreColor(),
          lineWidth: importedSettings.width,
          lineCap: "round",
          lineJoin: "round",
        ),
      );

      setState(() {
        userMovedMap = true;
        isProgrammaticMove = true;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mapController != null) {
          mapController!
              .animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(next.minLat!, next.minLon!),
                    northeast: LatLng(next.maxLat!, next.maxLon!),
                  ),
                  left: 50,
                  top: 50,
                  right: 50,
                  bottom: 50,
                ),
              )
              .then((_) {
                if (mounted) setState(() => isProgrammaticMove = false);
              });
        }
      });
    });

    ref.listen(importedTrackSettingsProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;

      mapController!.setLayerProperties(
        "imported_track_layer",
        LineLayerProperties(
          lineColor: next.color.toMapLibreColor(),
          lineWidth: next.width,
          lineCap: "round",
          lineJoin: "round",
        ),
      );
    });

    ref.listen(trackFollowNotifierProvider, (prev, next) {
      if (next.showBackOnTrackSnackbar == true) {
        AppMessages.showBackOnTrackPersistentSnackbar(context, ref);

        ref
            .read(trackFollowNotifierProvider.notifier)
            .dismissBackOnTrackAlert();
      }
    });

    ref.listen(trackFollowNotifierProvider, (prev, next) async {
      final wasFalse = prev?.showReverseTrackDialog == false;
      final isTrue = next.showReverseTrackDialog == true;

      if (wasFalse && isTrue) {
        // 🔥 Primer resetejar el flag al notifier
        ref
            .read(trackFollowNotifierProvider.notifier)
            .dismissReverseTrackDialog();

        final accept = await AppMessages.showReverseTrackDialog(context);

        if (accept == true) {
          ref.read(trackFollowNotifierProvider.notifier).reverseImportedTrack();
        }
      }
    });

    ref.listen(trackFollowNotifierProvider, (prev, next) {
      if (next.showEndOfTrackSnackbar == true) {
        AppMessages.showEndOfTrackSnackBar(context);

        ref.read(trackFollowNotifierProvider.notifier).dismissEndOfTrackAlert();
      }
    });

    ref.listen(trackFollowNotifierProvider, (prev, next) {
      if (next.showOffTrackSnackbar == true) {
        AppMessages.showOffTrackPersistentSnackbar(context, ref);

        // 🔥 IMPORTANT: reset immediat
        ref.read(trackFollowNotifierProvider.notifier).clearOffTrackSnackbar();
      }
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

                title: const Text(
                  'GpxGo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),

                actions: [
                  // 🔥 Píndola de gravació
                  RecordingStatusBar(
                    state: track.recordingState,
                    duration: track.duration,
                  ),

                  const SizedBox(width: 12),

                  // Botó d'importació
                  IconButton(
                    icon: const Icon(Icons.file_upload_outlined, size: 26),
                    onPressed: () {
                      pickGpxAndImport(
                        context: context,
                        ref: ref,
                        mapController: mapController,
                      );
                    },
                  ),

                  // Botó de settings
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 👉 Ara sí: GpsAccuracyBars a la dreta del tot
                  const GpsAccuracyBars(),

                  const SizedBox(width: 8),
                ],
              ),

        body: Stack(
          children: [
            RepaintBoundary(
              child: MapLibreMap(
                trackCameraPosition: true,
                compassEnabled: false,
                styleString: "assets/osm_style.json",
                initialCameraPosition: CameraPosition(
                  target: _initialCameraTarget!,
                  zoom: _initialZoom,
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
                onCameraIdle: () async {
                  final pos = await mapController!.cameraPosition;

                  ref.read(mapZoomProvider.notifier).update(pos!.zoom);
                  ref
                      .read(mapCenterLatProvider.notifier)
                      .update(pos.target.latitude);
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
              const Positioned(
                top: 10,
                left: 10,
                child: CompassAltitudeScaleRow(),
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
                    // FloatingAltitudePanel(),
                    // const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RecordingFollowingSimulatorPage(),
                        ),
                      ),
                      child: Text('Debug'),
                    ),
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
                    // BOTÓ DE CENTRAR MAPA
                    if (userMovedMap)
                      GestureDetector(
                        onTap: () {
                          final gps = ref.read(gpsManagerProvider);
                          if (gps.position == null) return;

                          final pos = gps.position!;

                          setState(() {
                            userMovedMap = false;
                            isProgrammaticMove = true;
                          });

                          mapController
                              ?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(pos.latitude, pos.longitude),
                                ),
                              )
                              .then((_) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (mounted) {
                                      setState(
                                        () => isProgrammaticMove = false,
                                      );
                                    }
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
                            Icons.gps_fixed,
                            color: Colors.white,
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
                  final ok = await requestLocationPermissionsUnified(
                    context,
                    ref,
                  );
                  if (!ok) return;

                  setState(() {
                    userMovedMap = false;
                    isProgrammaticMove = true;
                  });

                  await RecordingHandler.start(context, ref, mapController);

                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => isProgrammaticMove = false);
                  });

                  setState(() => _isPanelExpanded = false);
                },

                onPause: () => RecordingHandler.pause(ref),
                onResume: () => RecordingHandler.resume(ref),
                onStop: () => _handleStopProcess(context, ref),
                hasImportedTrack: hasImportedTrack,

                isFollowingTrack: trackFollowState.isFollowing,
                onImportTrack: () {
                  pickGpxAndImport(
                    context: context,
                    ref: ref,
                    mapController: mapController,
                  );
                },

                onFollowTrack: _onFollowTrack,
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

    // 1. Proposar nom editable
    final suggested = buildGpxFilename().replaceAll(".gpx", "");
    final name = await AppMessages.askGpxFilename(context, suggested);

    if (name == null || name.isEmpty) return;

    // 2. Exportar i compartir
    await exportGpx(name, ref, context);

    if (!mounted) return;

    // 3. Preguntar si vol eliminar o mantenir
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
