import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/features/elevation_profile/elevation_profile_screen.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/models/waypoint.dart';
import 'package:gpxly/notifiers/gps_speed_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_settings_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/notifiers/waypoints_notifier.dart';
import 'package:gpxly/screens/settings/settings_screen.dart';
import 'package:gpxly/screens/stats_screen.dart';

import 'package:gpxly/services/gps_manager.dart';
import 'package:gpxly/services/gpx_import_flow.dart';
import 'package:gpxly/services/location_permission_flow.dart';
import 'package:gpxly/services/recording_handler.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/ui/bottom_bar/bottom_bar_container.dart';
import 'package:gpxly/utils/color_extensions.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
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
  bool waypointLayersReady = false;
  DateTime? _lastBackPress;
  LatLng? _lastPosition;
  Timer? _animationTimer;
  Symbol? _userSymbol;
  bool _cameraDrivenByAnimation = false;

  late AnimationController _posController;
  LatLng _latLngA = const LatLng(0, 0);
  LatLng _latLngB = const LatLng(0, 0);

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

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Inicialitzem el motor de l'animació
    _posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 2. Escuchem cada frame de l'animació
    _posController.addListener(_onAnimationTick);

    // 3. Gestió del final de l'animació
    _posController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cameraDrivenByAnimation = false;

        if (mounted) {
          setState(() => isProgrammaticMove = false);
        }

        final trackData = ref.read(trackProvider);
        if (trackData.recordingState == RecordingState.recording) {
          _updateTrackLineSource(trackData.coordinates);
        }
      }
    });

    _loadLastPosition();
    Future.microtask(
      () => ref.read(permissionsProvider.notifier).checkPermissions(),
    );
  }

  void _onAnimationTick() {
    if (!mounted || mapController == null || !styleInitialized) return;

    final double t = _posController.value;
    final double lat = lerpDouble(_latLngA.latitude, _latLngB.latitude, t)!;
    final double lng = lerpDouble(_latLngA.longitude, _latLngB.longitude, t)!;
    final currentPos = LatLng(lat, lng);

    _updateUserLocationSource(lng, lat);

    final trackData = ref.read(trackProvider);
    if (trackData.recordingState == RecordingState.recording) {
      // ⚠️ CORRECCIÓN CLAVE:
      // Cogemos todos los puntos, pero ELIMINAMOS el último (el punto B real)
      // para añadir en su lugar el punto animado actual.
      final coords = List<List<double>>.from(trackData.coordinates);
      if (coords.isNotEmpty) {
        coords.removeLast();
      }
      coords.add([lng, lat]);

      _updateTrackLineSource(coords);
    }

    // 3. SMART CENTER
    // 3. SMART CENTER
    if (!userMovedMap) {
      _cameraDrivenByAnimation = true;
      mapController!.moveCamera(CameraUpdate.newLatLng(currentPos));
    }
  }

  void _updateUserLocationSource(double lon, double lat) {
    if (mapController == null) return;

    mapController!.updateSymbol(
      _userSymbol!,
      SymbolOptions(geometry: LatLng(lat, lon)),
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
    _posController
        .dispose(); // <--- Añade esto para limpiar el AnimationController
    _animationTimer?.cancel(); // Mantén esto si aún usas timers en otras partes
    WidgetsBinding.instance.removeObserver(this); // Limpieza del observer
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
    // Si l'animació està activa, ignorem qualsevol canvi intern del mapa
    if (isProgrammaticMove || _posController.isAnimating) return;
    userMovedMap = true;

    final moving = mapController?.isCameraMoving ?? false;
    if (moving && !userMovedMap) {
      setState(() => userMovedMap = true);
    }
  }

  void _handleStopProcess(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();

    final result = await AppMessages.showStopRecordingDialog(context);
    if (!mounted) return;
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
    return AppMessages.showDeleteTrackDialog(context);
  }

  bool isConsistentlyIncreasing(List<double> values) {
    for (int i = 1; i < values.length; i++) {
      if (values[i] < values[i - 1]) return false;
    }
    return true;
  }

  // void _animateGpsPosition(LatLng newPos) {
  //   if (!mounted || mapController == null) return;

  //   setState(() => isProgrammaticMove = true);

  //   if (_latLngB.latitude == 0) {
  //     _latLngA = newPos;
  //     _latLngB = newPos;
  //     _updateUserLocationSource(newPos.longitude, newPos.latitude);
  //     setState(() => isProgrammaticMove = false);
  //     return;
  //   }

  //   _latLngA = _latLngB;
  //   _latLngB = newPos;

  //   _cameraDrivenByAnimation = true;
  //   _posController.forward(from: 0.0);
  // }

  void _animateGpsPosition(LatLng newPos) {
    if (!mounted || mapController == null) return;

    // 1. NO centrem el mapa aquí
    // (Això és el canvi important)

    // 2. Actualitzem posicions internes
    _latLngA = newPos;
    _latLngB = newPos;

    // 3. Punt blau immediat (posició final real)
    _updateUserLocationSource(newPos.longitude, newPos.latitude);

    // 4. Obtenim track
    final trackData = ref.read(trackProvider);
    final coords = trackData.coordinates;

    if (coords.length < 2) {
      _updateTrackLineSource(coords);
      return;
    }

    // 5. Penúltim i últim punt real
    final prevReal = LatLng(
      coords[coords.length - 2][1],
      coords[coords.length - 2][0],
    );
    final lastReal = LatLng(coords.last[1], coords.last[0]);

    // 6. Pintem track sense l’últim punt real
    final coordsWithoutLast = coords.sublist(0, coords.length - 1);
    _updateTrackLineSource(coordsWithoutLast);

    // ---------------------------------------------------------
    // 🔥 ANIMACIÓ AMB TIMER (sense moure càmera a cada tick)
    // ---------------------------------------------------------

    const int steps = 30;
    int currentStep = 0;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentStep++;
      final t = currentStep / steps;

      // Interpolació
      final lat =
          prevReal.latitude + (lastReal.latitude - prevReal.latitude) * t;
      final lng =
          prevReal.longitude + (lastReal.longitude - prevReal.longitude) * t;

      // 1. Punt blau animat
      _updateUserLocationSource(lng, lat);

      // 2. Segment animat
      final animatedCoords = List<List<double>>.from(coordsWithoutLast)
        ..add([lng, lat]);

      _updateTrackLineSource(animatedCoords);

      // 3. Final de l’animació
      // 3. Final de l’animació
      if (currentStep >= steps) {
        timer.cancel();

        // Pintem track real complet
        _updateTrackLineSource(coords);

        // Punt blau final
        _updateUserLocationSource(lastReal.longitude, lastReal.latitude);

        // 🔥 Centrat suau del mapa NOMÉS ara
        if (!userMovedMap) {
          isProgrammaticMove = true;
          mapController!.animateCamera(
            CameraUpdate.newLatLng(lastReal),
            duration: Duration(milliseconds: 100),
          );
        }

        // Alliberem el flag després que MapLibre acabi
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) isProgrammaticMove = false;
        });
      }
    });
  }

  void _updateTrackLineSource(List<List<double>> coords) {
    if (mapController == null) return;
    mapController!.setGeoJsonSource("track_line", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coords},
        },
      ],
    });
  }

  Widget _buildSquareButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, // 🎯 Nova amplada de la brúixola
        height: 52, // 🎯 Quadrat perfecte
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26, // 🎯 Una mica més petita per la nova mida de 52px
        ),
      ),
    );
  }

  void _onAddWaypoint(BuildContext context, WidgetRef ref) async {
    final track = ref.read(trackProvider);

    // Si no hi ha punts → no fem res
    if (track.coordinates.isEmpty) return;

    // Última posició del track
    final last = track.coordinates.last;

    // 1) Obrim el diàleg amb nom suggerit
    final waypoints = ref.read(waypointsProvider);
    final suggestedName = "Punt ${waypoints.length + 1}";

    final name = await AppMessages.showAddWaypointDialog(
      context,
      suggestedName: suggestedName,
    );

    // Si l’usuari cancel·la → sortim
    if (name == null || name.isEmpty) return;

    // 2) Creem el waypoint
    final wp = Waypoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lat: last[1],
      lon: last[0],
      trackIndex: track.coordinates.length - 1,
    );

    // 3) Guardem al provider
    ref.read(waypointsProvider.notifier).add(wp);
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final recordingState = track.recordingState;
    final trackSettings = ref.watch(trackSettingsProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final hasImportedTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;
    final trackFollowState = ref.watch(trackFollowNotifierProvider);

    // Listener dins build (Riverpod obliga)
    // 1. LISTENER DEL GPS (El que manda)
    ref.listen<GpsManagerState>(gpsManagerProvider, (prev, next) {
      if (!mounted ||
          mapController == null ||
          !styleInitialized ||
          next.position == null)
        return;

      final pos = LatLng(next.position!.latitude, next.position!.longitude);
      _animateGpsPosition(pos);
    });

    // 2. LISTENER DEL TRACK (El pasivo)
    ref.listen(trackProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;

      final isRecording = next.recordingState == RecordingState.recording;

      // SI ESTAMOS GRABANDO: No pintamos desde aquí.
      // Delegamos el dibujo a la función _animateGpsPosition que se dispara por el GPS.
      if (isRecording) return;

      // SI NO ESTAMOS GRABANDO (ej. pausa o stop): Pintamos normal.
      _updateTrackLineSource(next.coordinates);
    });

    ref.listen(waypointsProvider, (prev, next) async {
      if (!styleInitialized || !waypointLayersReady || mapController == null) {
        return;
      }

      updateWaypointsOnMap(mapController!, next);

      await animateWaypointAppearance(
        mapController!,
        'waypoints_recorded_layer',
      );

      await animateWaypointAppearance(
        mapController!,
        'waypoints_imported_layer',
      );
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
                onCameraMove: (_) {
                  if (isProgrammaticMove) return;
                  userMovedMap = true;
                },

                onCameraIdle: () {
                  isProgrammaticMove = false;
                },

                onMapCreated: (controller) {
                  mapController = controller;
                  // Opcional: pots eliminar el listener de _onMapChanged si
                  // aquest també et donava problemes amb el Smart Center.
                },
                onStyleLoadedCallback: () async {
                  await setupUserLocationLayer(mapController!);

                  // Creem el símbol del punt blau
                  _userSymbol = await mapController!.addSymbol(
                    SymbolOptions(
                      geometry: _latLngB,
                      iconImage: "user_icon",
                      iconSize: 1.0,
                      zIndex: 10,
                    ),
                  );

                  await setupWaypointLayers(mapController!);
                  waypointLayersReady = true;
                  styleInitialized = true;

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
                    final lastPos = LatLng(last[1], last[0]);

                    _latLngB = lastPos;

                    if (_userSymbol != null) {
                      mapController!.updateSymbol(
                        _userSymbol!,
                        SymbolOptions(geometry: lastPos),
                      );
                    }

                    if (!userMovedMap) {
                      // Marquem com a programàtic per al zoom/posicionament inicial
                      isProgrammaticMove = true;
                      mapController!.moveCamera(
                        CameraUpdate.newLatLng(lastPos),
                      );
                    }

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
                top: 10,
                left: 10,
                child: RecordingStatusBar(
                  state: track.recordingState,
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
                    const CompassScalePanel(), // Aquest ja fa 62px d'ample
                    const SizedBox(height: 8),

                    // BOTÓ DE PERFIL D'ELEVACIÓ
                    _buildSquareButton(
                      icon: Icons.terrain_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ElevationProfileScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // BOTÓ DE DADES (ESTADÍSTIQUES)
                    _buildSquareButton(
                      icon: Icons.bar_chart,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackStatsScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    if (recordingState == RecordingState.recording) ...[
                      _buildSquareButton(
                        icon: Icons.add_location_alt_outlined,
                        onTap: () => _onAddWaypoint(context, ref),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // BOTÓ DE CENTRAR MAPA
                    if (userMovedMap)
                      _buildSquareButton(
                        icon: Icons.gps_fixed,
                        // Dentro del onTap del botón gps_fixed:
                        onTap: () {
                          setState(() {
                            userMovedMap = false;
                            isProgrammaticMove = true; // Bloqueo manual
                          });

                          mapController
                              ?.animateCamera(CameraUpdate.newLatLng(_latLngB))
                              .then((_) {
                                // Esperamos un pelín a que el mapa se detenga del todo antes de liberar
                                Future.delayed(
                                  const Duration(milliseconds: 200),
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
                      ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: _fullScreen
                    ? const SizedBox.shrink() // Si està en fullScreen no mostrem res
                    : BottomBarContainer(
                        isExpanded: _isPanelExpanded,
                        onToggle: () => setState(
                          () => _isPanelExpanded = !_isPanelExpanded,
                        ),

                        // L'estat de gravació que ve del teu provider/model
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

                          await RecordingHandler.start(
                            context,
                            ref,
                            mapController,
                          );
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted)
                              setState(() => isProgrammaticMove = false);
                          });

                          setState(() => _isPanelExpanded = false);
                        },
                        onPause: () => RecordingHandler.pause(ref),
                        onResume: () => RecordingHandler.resume(ref),
                        onStop: () => _handleStopProcess(context, ref),

                        hasImportedTrack: hasImportedTrack,
                        isFollowingTrack: trackFollowState.isFollowing,

                        // ... resta de paràmetres iguals
                        onImportTrack: () {
                          pickGpxAndImport(
                            context: context,
                            ref: ref,
                            mapController: mapController,
                          );
                        },

                        onFollowTrack: () {
                          if (trackFollowState.isFollowing) {
                            // 1. ATURAR CÀLCULS (Estalvi de bateria/CPU)
                            ref
                                .read(trackFollowNotifierProvider.notifier)
                                .stopFollowing();

                            // 2. NETEJAR RUTA (Per poder importar-ne una de nova)
                            ref.read(importedTrackProvider.notifier).clear();
                          } else {
                            // Si no està seguint, iniciem normalment
                            _onFollowTrack();
                          }
                        },
                      ),
              ),
            ],
          ],
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
