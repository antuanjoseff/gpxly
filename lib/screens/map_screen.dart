import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show OneSequenceGestureRecognizer, EagerGestureRecognizer;
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
import 'package:gpxly/services/gpx_import_flow.dart';
import 'package:gpxly/services/location_permission_flow.dart';
import 'package:gpxly/services/recording_handler.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/services/gpx_exporter.dart';
import 'package:gpxly/ui/bottom_bar/bottom_bar_container.dart';
import 'package:gpxly/utils/color_extensions.dart';
import 'package:gpxly/utils/map_animator.dart';
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
  bool _isPanelExpanded = true;
  bool _fullScreen = false;
  LatLng? _initialCameraTarget;
  double _initialZoom = 14;
  bool waypointLayersReady = false;
  DateTime? _lastBackPress;
  bool smartCenterEnabled = true;
  bool isProgrammaticMove = false;
  Timer? smartCenterDebounce;

  late MapAnimator mapAnimator;

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

    _loadLastPosition();
    Future.microtask(
      () => ref.read(permissionsProvider.notifier).checkPermissions(),
    );
  }

  void _centerOnUser() {
    final pos = ref.read(trackProvider).currentPosition;
    if (pos == null || mapController == null) return;

    isProgrammaticMove = true;

    mapController!.animateCamera(CameraUpdate.newLatLng(pos));
    // 🔥 Reset de seguretat
    Future.delayed(const Duration(milliseconds: 300), () {
      isProgrammaticMove = false;
    });
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
    WidgetsBinding.instance.removeObserver(this); // Limpieza del observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {}
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

    // 2. LISTENER DEL TRACK (El pasivo)
    ref.listen(trackProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

      mapAnimator.updateFromTrack(next);

      // Si SmartCenter està actiu → seguir el punt blau
      if (smartCenterEnabled && next.currentPosition != null) {
        isProgrammaticMove = true;

        mapController!.animateCamera(
          CameraUpdate.newLatLng(next.currentPosition!),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          isProgrammaticMove = false;
        });
      }
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
              child: Listener(
                onPointerMove: (PointerMoveEvent event) {
                  if (smartCenterEnabled) {
                    setState(() => smartCenterEnabled = false);
                  }
                },
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
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                    setState(() => _fullScreen = false);
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
                    // Opcional: pots eliminar el listener de _onMapChanged si
                    // aquest també et donava problemes amb el Smart Center.
                  },
                  onStyleLoadedCallback: () async {
                    await setupUserLocationLayer(mapController!);
                    await setupWaypointLayers(mapController!);

                    mapAnimator = MapAnimator(mapController!);

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
                  },
                ),
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
                    if (!smartCenterEnabled)
                      _buildSquareButton(
                        icon: Icons.gps_fixed,
                        onTap: () {
                          setState(() => smartCenterEnabled = true);
                          _centerOnUser();
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

                          await RecordingHandler.start(context, ref);
                          final map = mapController;
                          final pos = ref.read(trackProvider).currentPosition;

                          if (map != null && pos != null) {
                            isProgrammaticMove = true;
                            map.animateCamera(
                              CameraUpdate.newLatLngZoom(pos, 18),
                            );

                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                isProgrammaticMove = false;
                              },
                            );
                          }

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

    // ... després de exportGpx ...

    if (eliminar == true) {
      // 1. Indiquem que no volem recuperar res el pròxim cop
      prefs.setBool("preserve_track_on_start", false);

      // 2. Cridem al mètode correcte que hem definit al Notifier
      ref.read(trackProvider.notifier).reset();

      // 3. També hauries de netejar els waypoints si n'hi havia
      ref.read(waypointsProvider.notifier).clear();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }
}
