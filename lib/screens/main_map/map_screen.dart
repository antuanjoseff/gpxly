// lib/screens/map/map_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';

// Notifiers natius de Senda
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/map_bearing_provider.dart';
import 'package:senda/notifiers/map_selection_tool_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/providers/barometer_provider.dart';

// Widgets independents
import 'package:senda/screens/main_map/widgets/map_app_bar.dart';
import 'package:senda/screens/main_map/widgets/map_base_layer.dart';
import 'package:senda/screens/main_map/widgets/map_bottom_controls.dart';
import 'package:senda/screens/main_map/widgets/map_bottom_controls/elevation_panel.dart';
import 'package:senda/screens/main_map/widgets/map_bottom_controls/layout_utils.dart';
import 'package:senda/screens/main_map/widgets/map_selection_reticle.dart';
import 'package:senda/screens/main_map/widgets/map_selection_top_button.dart';
import 'package:senda/screens/main_map/widgets/map_top_controls.dart';
import 'package:senda/theme/app_colors.dart';

// HELPERS
import 'package:senda/screens/main_map/helpers/map_geometry_helper.dart';
import 'package:senda/screens/main_map/helpers/navigation_flow_handler.dart';
import 'package:senda/screens/main_map/helpers/recording_flow_handler.dart';

// Serveis i utilitats
import 'package:senda/services/hgt_service.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/services/recording_handler.dart';
import 'package:senda/theme/app_dimensions.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/utils/color_extensions.dart';
import 'package:senda/utils/map_animator.dart';
import 'package:senda/utils/map_layers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senda/utils/distance_utils.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  MapLibreMapController? mapController;
  bool styleInitialized = false;
  bool _fullScreen = false;
  LatLng? _initialCameraTarget;
  double _initialZoom = 14;
  bool waypointLayersReady = false;
  DateTime? _lastBackPress;
  bool smartCenterEnabled = true;
  bool hasDoneFirstFixZoom = false;
  bool isProgrammaticMove = false;
  bool isImportingGpx = false;
  bool _isShowingReverseDialog = false;
  bool hasDoneRecoveryFit = false;
  DateTime _lastPrefsSave = DateTime.now();
  LatLng? _lastCameraCenter;

  // Índexs del gràfic
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? selectedIndexGraph;
  int? _prevWpIndex;
  int? _lastWpIndex;

  bool _isChartCollapsed = false;
  DateTime _lastMapUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _mapThrottleMs = 32;

  late MapAnimator mapAnimator;
  double _currentMapPadding = 0;

  Timer? _waypointPulseTimer;
  double _pulseValue = 0.0;
  bool _pulseIncreasing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeBarometerChannel.start();
    _loadLastPosition();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await PermissionsService.ensureBasicLocation(context);
      if (ok) {
        await ref.read(locationProvider.notifier).ensureGpsStarted();
        final userGps = ref.read(locationProvider);
        if (userGps != null &&
            (_initialCameraTarget == null ||
                _initialCameraTarget!.latitude == 0)) {
          setState(() {
            _initialCameraTarget = userGps.position;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NativeBarometerChannel.stop();
    super.dispose();
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble("last_lat");
    final lon = prefs.getDouble("last_lon");

    if (mounted) {
      setState(() {
        if (lat != null && lon != null) {
          _initialCameraTarget = LatLng(lat, lon);
          _initialZoom = 14.0;
        } else {
          _initialCameraTarget = const LatLng(41.3851, 2.1734);
          _initialZoom = 7.0;
        }
      });
    }
  }

  Future<void> _savePositionToPrefs() async {
    final userGps = ref.read(locationProvider);
    if (userGps != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("last_lat", userGps.position.latitude);
      await prefs.setDouble("last_lon", userGps.position.longitude);
      _lastPrefsSave = DateTime.now();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await ref.read(permissionsProvider.notifier).checkServiceStatus();
      await Future.delayed(const Duration(milliseconds: 300));
      final perm = ref.read(permissionsProvider);

      if (perm.serviceEnabled) {
        if (perm.shouldResumeRecording) {
          ref.read(permissionsProvider.notifier).consumeSignal();
          RecordingHandler.start(context, ref);
        } else if (perm.shouldResumeFollowing) {
          ref.read(permissionsProvider.notifier).consumeFollowSignal();
          _onFollowTrack();
        }
      }
    }
  }

  void safeMoveCamera(CameraUpdate update) {
    if (isImportingGpx || mapController == null) return;
    mapController!.moveCamera(update);
  }

  void safeAnimateCamera(CameraUpdate update) {
    mapController?.animateCamera(update);
  }

  void _centerOnUser() {
    final userGps = ref.read(locationProvider);
    if (userGps == null || mapController == null) return;

    setState(() {
      _lastCameraCenter = null;
      smartCenterEnabled = true;
    });

    safeAnimateCamera(CameraUpdate.newLatLng(userGps.position));
  }

  Future<void> _onFollowTrack() async {
    final notifier = ref.read(navigationProvider.notifier);
    final state = ref.read(navigationProvider);

    if (state.isFollowing) {
      notifier.stopFollowing();
      return;
    }
    await notifier.startFollowing(context, mapController);
  }

  void _openRecordingControl(
    BuildContext context,
    WidgetRef ref, [
    String? action,
  ]) {
    RecordingFlowHandler(ref: ref, context: context).openRecordingControl(
      mapController: mapController,
      onToggleSmartCenter: (val) => setState(() => smartCenterEnabled = val),
      onUpdateLastCamera: (pos) => _lastCameraCenter = pos,
      onToggleProgrammaticMove: (val) {
        setState(() {
          isProgrammaticMove = val;
          _isChartCollapsed = true;
        });
      },
      safeAnimateCamera: safeAnimateCamera,
      action: action,
    );
  }

  void _openNavigationControl(
    BuildContext context,
    WidgetRef ref,
    bool hasTrack,
  ) async {
    final navigationState = ref.read(navigationProvider);

    if (hasTrack && !navigationState.isFollowing) {
      final bool permisosConcedidos =
          await PermissionsService.ensureBackgroundLocationWithDialog(context);

      if (!permisosConcedidos) return;
    }

    if (mounted) {
      NavigationFlowHandler(ref: ref, context: context).openNavigationControl(
        mapController: mapController,
        hasImportedTrack: hasTrack,
        fitToBounds: (coords, {instant = false}) {
          // final padding = _computeMapPadding(context, hasTrack);

          MapGeometryHelper(ref: ref, mapController: mapController).fitToBounds(
            coords,
            instant: instant,
            left: 40,
            right: 40,
            // top: padding.top,
            // bottom: padding.bottom,
          );
        },
      );
    }
  }

  Widget _buildSquareButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.iconBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: AppColors.iconForegroundColor, size: 26),
      ),
    );
  }

  void _onAddWaypoint(BuildContext context, WidgetRef ref) async {
    final pos = ref.read(locationProvider);
    if (pos == null) {
      AppMessages.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.waypointNoGps,
      );
      return;
    }

    final lastLat = pos.position.latitude;
    final lastLon = pos.position.longitude;
    final lastAlt = pos.altitude;

    final (correctedAlt, _) = await HgtService().getCorrectedElevation(
      lastLat,
      lastLon,
      lastAlt,
    );

    final waypoints = ref.read(waypointsProvider);
    final name = await AppMessages.showAddWaypointDialog(
      context,
      suggestedName: "Punt ${waypoints.length + 1}",
    );

    if (name == null || name.isEmpty) return;

    final wp = Waypoint(
      id: "rec_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      lat: lastLat,
      lon: lastLon,
      ele: correctedAlt,
      trackIndex: ref.read(trackRecordingProvider).points.length - 1,
      distanceAtPoint: ref.read(trackRecordingProvider).distance,
      time: DateTime.now(),
    );

    ref.read(waypointsProvider.notifier).add(wp);
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng latLng,
    String featureId,
    String layerId,
    Annotation? annotation,
  ) async {
    final features = await mapController?.queryRenderedFeatures(point, [
      'waypoints_recorded_layer',
      'waypoints_imported_layer',
    ], null);

    if (features == null || features.isEmpty) return;

    final dynamic feature = features.first;
    final String? wpId = feature['properties']?['waypoint_id'];
    if (wpId == null) return;

    final recorded = ref.read(waypointsProvider);
    final imported = ref.read(importedWaypointsProvider);
    final waypoint = [...recorded, ...imported].firstWhere((w) => w.id == wpId);

    final int wpTrackIndex = waypoint.trackIndex;

    if (!_isChartCollapsed) {
      final currentSelection = ref.read(elevationSelectionProvider);

      if (currentSelection.mode == SelectionMode.range) {
        final Set<int> allWpIndexes = [
          ...recorded,
          ...imported,
        ].map((w) => w.trackIndex).toSet();

        ref
            .read(elevationSelectionProvider.notifier)
            .toggleWaypoint(wpTrackIndex, allWpIndexes);

        return;
      } else {
        ref
            .read(elevationSelectionProvider.notifier)
            .setSinglePoint(wpTrackIndex);
        return;
      }
    }

    Duration? elapsed;
    final track = wpId.startsWith('rec_')
        ? ref.read(trackRecordingProvider)
        : ref.read(importedTrackProvider);

    if (track != null && track.timestamps.isNotEmpty && waypoint.time != null) {
      elapsed = waypoint.time!.difference(track.timestamps.first);
    }

    if (mounted) {
      AppMessages.showWaypointDetails(context, ref, waypoint, elapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    final pressure = ref.watch(barometerProvider).value;
    final isRunning = ref.watch(locationProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(locationProvider.notifier).isSimulationPaused;
    final trackSettings = ref.watch(trackSettingsProvider);
    // ─────────────────────────────────────────────────────────────
    // 🛡️ RECEPTORS I OIENTS DE SEGUIDAMENT ASÍNCRON
    ref.listen(elevationSelectionProvider, (previous, next) {
      if (!styleInitialized || mapController == null) return;

      final bool isRange = next.mode == SelectionMode.range;

      if (isRange) {
        startWaypointPulse(mapController!);
      } else {
        stopWaypointPulse(mapController!);
      }

      if (!_isChartCollapsed) {
        final geom = MapGeometryHelper(ref: ref, mapController: mapController);

        final int? indexIniciUnificat =
            next.startTrackIndex ?? next.singlePointIndex;

        setChartInteractionGeometry(
          mapController!,
          rangeStartCoords: geom.getCoordsFromGlobalIndex(indexIniciUnificat),
          rangeEndCoords: geom.getCoordsFromGlobalIndex(next.endTrackIndex),
          hoverCoords: null,
        );
      }
    });

    // 🛰️ OIENT 1: POSICIÓ DE L’USUARI
    ref.listen<UserPosition?>(locationProvider, (prev, next) async {
      if (!styleInitialized || mapController == null || next == null) return;

      final recState = ref.read(trackRecordingProvider).recordingState;
      if (recState != RecordingState.recording) {
        mapController?.setGeoJsonSource("user_location", {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  next.position.longitude,
                  next.position.latitude,
                ],
              },
            },
          ],
        });

        mapAnimator.animateUserPosition(
          next.position,
          bottomPadding: _currentMapPadding,
        );
      }

      final ara = DateTime.now();
      if (ara.difference(_lastPrefsSave).inMinutes >= 5) {
        _savePositionToPrefs();
      }

      if (isImportingGpx) return;

      final bool isRealSignal = next.accuracy < 100.0;

      if (!hasDoneFirstFixZoom && isRealSignal) {
        setState(() {
          hasDoneFirstFixZoom = true;
          isProgrammaticMove = true;
          _lastCameraCenter = next.position;
        });

        safeAnimateCamera(CameraUpdate.newLatLngZoom(next.position, 16.0));

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => isProgrammaticMove = false);
          }
        });
        return;
      }

      if (smartCenterEnabled &&
          !isProgrammaticMove &&
          isRealSignal &&
          recState != RecordingState.paused) {
        double distanceSinceLastMove = 999.0;

        if (_lastCameraCenter != null) {
          distanceSinceLastMove = calculateDistanceManual(
            _lastCameraCenter!.latitude,
            _lastCameraCenter!.longitude,
            next.position.latitude,
            next.position.longitude,
          );
        }

        if (distanceSinceLastMove > 3.0) {
          setState(() {
            isProgrammaticMove = true;
            _lastCameraCenter = next.position;
          });

          safeAnimateCamera(CameraUpdate.newLatLng(next.position));

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => isProgrammaticMove = false);
            }
          });
        }
      }
    });

    // 📊 OIENT 2: GRAVACIÓ FÍSICA
    ref.listen<Track>(trackRecordingProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

      if (next.recordingState == RecordingState.recording) {
        mapAnimator.updateFromTrack(next, !smartCenterEnabled);
      }

      if (isImportingGpx) return;

      final bool isRecoveringTrack =
          (prev == null || prev.points.isEmpty) &&
          next.points.length > 1 &&
          !hasDoneRecoveryFit;

      if (isRecoveringTrack) {
        hasDoneRecoveryFit = true;
        // final padding = _computeMapPadding(context, true);

        MapGeometryHelper(ref: ref, mapController: mapController).fitToBounds(
          next.coordinates,
          instant: true,
          left: 40,
          right: 40,
          // top: padding.top,
          // bottom: padding.bottom,
        );
      }
    });

    // OIENT 3: TRACK IMPORTAT
    ref.listen<Track?>(importedTrackProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;
      // 🔥 MOSTRAR AUTOMÀTICAMENT EL PANELL D’ELEVACIONS
      if (next != null && next.coordinates.isNotEmpty) {
        setState(() => _isChartCollapsed = false);
        _updateMapPaddingValue();
      }

      if (next == null) {
        setState(() {
          selectedIndexGraph = null;
          selectedIndexStart = null;
          selectedIndexEnd = null;
        });

        try {
          mapController!.setGeoJsonSource("imported_track", {
            "type": "FeatureCollection",
            "features": [],
          });
          setChartInteractionGeometry(mapController!);
        } catch (_) {}

        return;
      }

      final List<List<double>> coordsVisibles = ref
          .read(importedTrackProvider.notifier)
          .visibleCoordinates;

      if (coordsVisibles.isEmpty) {
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
            "geometry": {"type": "LineString", "coordinates": coordsVisibles},
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

      if (isImportingGpx && next.coordinates.isNotEmpty) {
        // final padding = _computeMapPadding(context, true);

        MapGeometryHelper(ref: ref, mapController: mapController).fitToBounds(
          next.coordinates,
          left: 40,
          right: 40,
          // top: padding.top,
          // bottom: padding.bottom,
        );
      }
    });

    // OIENT 4: WAYPOINTS
    ref.listen(waypointsProvider, (prev, next) async {
      if (!styleInitialized || !waypointLayersReady || mapController == null)
        return;

      updateWaypointSource(mapController!, 'waypoints_recorded_source', next);
      await animateWaypointAppearance(
        mapController!,
        'waypoints_recorded_layer',
      );
    });

    ref.listen(importedWaypointsProvider, (prev, next) async {
      if (!styleInitialized || !waypointLayersReady || mapController == null)
        return;

      updateWaypointSource(mapController!, 'waypoints_imported_source', next);
      await animateWaypointAppearance(
        mapController!,
        'waypoints_imported_layer',
      );
    });

    // OIENT 5: ESTILS VISUALS
    ref.listen(trackSettingsProvider, (previous, next) {
      if (mapController == null || !styleInitialized) return;

      mapController!.setLayerProperties(
        "track_line_layer",
        LineLayerProperties(
          lineColor: next.color.toMapLibreColor(),
          lineWidth: next.width,
          lineCap: "round",
          lineJoin: "round",
        ),
      );

      mapController!.setLayerProperties(
        "waypoints_recorded_layer",
        CircleLayerProperties(circleColor: next.color.toMapLibreColor()),
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

      mapController!.setLayerProperties(
        "waypoints_imported_layer",
        CircleLayerProperties(circleColor: next.color.toMapLibreColor()),
      );
    });
    // OIENT 6: ALERTES I DIÀLEGS
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      if (next.showBackOnTrackSnackbar == true) {
        AppMessages.showBackOnTrackPersistentSnackbar(context, ref);
        ref.read(navigationProvider.notifier).dismissBackOnTrackAlert();
      }
    });

    ref.listen<NavigationState>(navigationProvider, (prev, next) async {
      if (next.showReverseTrackDialog && !_isShowingReverseDialog) {
        _isShowingReverseDialog = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(navigationProvider.notifier).sounds.playReversedTrackSound();
        });

        final accept = await AppMessages.showReverseTrackDialog(context);

        if (accept == true) {
          ref.read(navigationProvider.notifier).reverseImportedTrack();
        } else {
          ref.read(navigationProvider.notifier).dismissReverseTrackDialog();
        }

        _isShowingReverseDialog = false;
      }
    });

    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      if (next.showEndOfTrackSnackbar == true) {
        AppMessages.showEndOfTrackSnackBar(context);
        ref.read(navigationProvider.notifier).dismissEndOfTrackAlert();
      }
    });

    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      if (next.showOffTrackSnackbar == true) {
        AppMessages.showOffTrackPersistentSnackbar(context, ref);
        ref.read(navigationProvider.notifier).clearOffTrackSnackbar();
      }
    });

    // CONTROL DE CÀRREGA DE LA CÀMERA
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
            : MapAppBar(
                pressure: pressure,
                isRunning: isRunning,
                isPaused: isPaused,
              ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 🗺️ CAPA 1: MAPA
                  MapBaseLayer(
                    initialCameraTarget: _initialCameraTarget!,
                    initialZoom: _initialZoom,
                    smartCenterEnabled: smartCenterEnabled,
                    isProgrammaticMove: isProgrammaticMove,
                    isFullScreen: _fullScreen,
                    onSmartCenterChanged: (val) =>
                        setState(() => smartCenterEnabled = val),
                    onFullScreenChanged: (val) =>
                        setState(() => _fullScreen = val),
                    onCameraMove: (CameraPosition position) {
                      ref
                          .read(mapBearingProvider.notifier)
                          .update(position.bearing);
                      ref.read(mapZoomProvider.notifier).update(position.zoom);
                      ref
                          .read(mapCenterLatProvider.notifier)
                          .update(position.target.latitude);
                    },
                    onMapCreated: (controller) {
                      mapController = controller;
                      mapAnimator = MapAnimator(controller);
                      controller.onFeatureTapped.add(_onFeatureTapped);
                    },
                    onStyleLoaded: () async {
                      await Future.delayed(const Duration(milliseconds: 100));

                      if (!mounted || mapController == null) return;

                      final trackSettings = ref.read(trackSettingsProvider);
                      final importedSettings = ref.read(
                        importedTrackSettingsProvider,
                      );

                      // 1. Inicializamos las fuentes y capas base de forma segura
                      await setupUserLocationLayer(mapController!);
                      await setupWaypointLayers(mapController!);

                      setState(() {
                        waypointLayersReady = true;
                        styleInitialized = true;
                      });

                      // 2. CONFIGURACIÓN CORRECTA DEL TRACK PRINCIPAL (LÍNEAS VECTORIALES)
                      mapController!.setLayerProperties(
                        "track_line_layer",
                        LineLayerProperties(
                          lineColor:
                              trackSettings.color.toMapLibreColor().isNotEmpty
                              ? trackSettings.color.toMapLibreColor()
                              : "#FF0000", // Fallback de seguridad si viene vacío
                          lineWidth: trackSettings.width,
                          lineCap: "round",
                          lineJoin: "round",
                        ),
                      );

                      // 3. CONFIGURACIÓN CORRECTA DEL TRACK IMPORTADO (LÍNEAS VECTORIALES)
                      mapController!.setLayerProperties(
                        "imported_track_layer",
                        LineLayerProperties(
                          lineColor:
                              importedSettings.color
                                  .toMapLibreColor()
                                  .isNotEmpty
                              ? importedSettings.color.toMapLibreColor()
                              : "#00A8E8", // Fallback de seguridad si viene vacío
                          lineWidth: importedSettings.width,
                          lineCap: "round",
                          lineJoin: "round",
                        ),
                      );
                    },
                  ),

                  // 🎯 RETICLE CENTRAL
                  const MapSelectionReticle(),

                  // 🔘 BOTÓ SUPERIOR DE SELECCIÓ
                  MapSelectionTopButton(mapController: mapController),

                  // 🎛️ HUD SUPERIOR
                  if (!_fullScreen)
                    MapTopControls(
                      mapController: mapController,
                      smartCenterEnabled: smartCenterEnabled,
                      onCenterOnUser: _centerOnUser,
                      onAddWaypoint: () => _onAddWaypoint(context, ref),
                    ),

                  // 🔥 **OPCIÓ A — PANELL D’ELEVACIONS ENGANXAT AL FONS**
                  if (!_isChartCollapsed)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ElevationPanel(
                        isCollapsed: _isChartCollapsed,
                        onCollapseChanged: (collapsed) {
                          setState(() => _isChartCollapsed = collapsed);
                          _updateMapPaddingValue();
                        },
                      ),
                    ),

                  // 🔘 BOTÓ DE L’EINA DE SELECCIÓ (es mou amb el panell)
                  if (!_isChartCollapsed)
                    Positioned(
                      right: 16,
                      bottom: _currentMapPadding + 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: ref.watch(mapSelectionToolProvider)
                              ? const Color(0xFF4CAF50)
                              : AppColors.iconBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                          boxShadow: ref.watch(mapSelectionToolProvider)
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withAlpha(100),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(mapSelectionToolProvider.notifier)
                                .toggle();
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            child: Icon(
                              ref.watch(mapSelectionToolProvider)
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              color: ref.watch(mapSelectionToolProvider)
                                  ? Colors.white
                                  : AppColors.iconForegroundColor,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 🎛️ BARRA INFERIOR (sense panell d’elevacions)
            if (!_fullScreen)
              MapBottomControls(
                isChartCollapsed: _isChartCollapsed,
                systemBottomPadding: systemBottomPadding,
                onAddWaypoint: () => _onAddWaypoint(context, ref),
                onOpenRecordingControl: (action) =>
                    _openRecordingControl(context, ref, action),
                onOpenNavigationControl: (hasTrack) =>
                    _openNavigationControl(context, ref, hasTrack),
                onHandleNavigationAction: _handleSendaNavigationAction,
                onToggleChart: () {
                  setState(() => _isChartCollapsed = !_isChartCollapsed);

                  if (_isChartCollapsed) {
                    ref
                        .read(elevationSelectionProvider.notifier)
                        .clearSelection();
                    ref.read(mapSelectionToolProvider.notifier).deactivate();

                    if (styleInitialized && mapController != null) {
                      stopWaypointPulse(mapController!);
                    }
                  }

                  _updateMapPaddingValue();
                },
              ),
          ],
        ),
      ),
    );
  }

  // 🏁 EXECUTOR RECEPTOR DE LA MÀQUINA D'ESTATS SEQÜENCIAL DE SENDA
  void _handleSendaNavigationAction(String? action) {
    print('action $action');
    if (action == null) return;

    switch (action) {
      case "follow":
        ref
            .read(navigationProvider.notifier)
            .startFollowing(context, mapController);
        break;

      case "clear_imported":
        ref.read(elevationSelectionProvider.notifier).clearSelection();
        ref.read(importedTrackProvider.notifier).clear();
        ref.read(importedWaypointsProvider.notifier).clear();
        ref.read(mapSelectionToolProvider.notifier).deactivate();
        break;

      case "toggle_pause":
        final currentNavState = ref.read(navigationProvider);
        ref.read(navigationProvider.notifier).state = currentNavState.copyWith(
          isPaused: !currentNavState.isPaused,
        );
        break;

      case "stop_follow":
        ref.read(elevationSelectionProvider.notifier).clearSelection();
        ref.read(navigationProvider.notifier).stopFollowing();
        ref.read(importedTrackProvider.notifier).clear();
        ref.read(importedWaypointsProvider.notifier).clear();
        ref.read(mapSelectionToolProvider.notifier).deactivate();
        break;
    }
  }

  void _updateMapPaddingValue() {
    if (!mounted) return;

    final importedTrack = ref.read(importedTrackProvider);
    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;

    final layout = LayoutUtils.fromContext(
      context,
      isChartCollapsed: _isChartCollapsed,
    );

    setState(() {
      if (hasTrack && layout.isPanelActive) {
        final double screenHeight = MediaQuery.of(context).size.height;
        final double calculatedChartHeight =
            screenHeight * AppDimensions.elevationChartHeightRatio;

        _currentMapPadding =
            calculatedChartHeight +
            AppDimensions.menuBarHeight +
            AppDimensions.mapSafetyPadding;
      } else {
        _currentMapPadding =
            AppDimensions.menuBarHeight + MediaQuery.of(context).padding.bottom;
      }
    });
  }

  // MapPadding _computeMapPadding(BuildContext context, bool hasTrack) {
  //   final media = MediaQuery.of(context);

  //   final layout = LayoutUtils.fromContext(
  //     context,
  //     isChartCollapsed: _isChartCollapsed,
  //   );

  //   final bool showChartData = !_isChartCollapsed && hasTrack;

  //   final double chartHeight = showChartData ? layout.chartHeight : 0;

  //   final double bottomPadding =
  //       media.padding.bottom +
  //       AppDimensions.menuBarHeight +
  //       chartHeight +
  //       64 +
  //       110;

  //   const double topPadding = 10;

  //   return MapPadding(top: topPadding, bottom: bottomPadding);
  // }
}

// class MapPadding {
//   final double top;
//   final double bottom;

//   const MapPadding({required this.top, required this.bottom});
// }
