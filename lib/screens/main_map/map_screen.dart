// lib/screens/map/map_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/models/navigation_state.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/notifiers/gps_speed_notifier.dart';
import 'package:strack_rec/notifiers/helpers/elevation_magnet_helper.dart';
import 'package:strack_rec/notifiers/helpers/thresholds.dart';

// Notifiers natius de STrack Rec
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/imported_track_settings_notifier.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/map_bearing_provider.dart';
import 'package:strack_rec/notifiers/map_selection_tool_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/permissions_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/track_settings_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_recorded_notifier.dart';
import 'package:strack_rec/providers/barometer_provider.dart';

// Widgets independents
import 'package:strack_rec/screens/main_map/widgets/map_app_bar.dart';
import 'package:strack_rec/screens/main_map/widgets/map_base_layer.dart';
import 'package:strack_rec/screens/main_map/widgets/map_bottom_controls.dart';
import 'package:strack_rec/screens/main_map/widgets/map_bottom_controls/navigation_submenu.dart';
import 'package:strack_rec/screens/main_map/widgets/map_bottom_controls/recording_submenu.dart';
import 'package:strack_rec/screens/main_map/widgets/map_selection_reticle.dart';
import 'package:strack_rec/screens/main_map/widgets/map_stack_widgets.dart';
import 'package:strack_rec/screens/main_map/widgets/map_top_controls.dart';
import 'package:strack_rec/theme/app_colors.dart';

// HELPERS
import 'package:strack_rec/screens/main_map/helpers/map_geometry_helper.dart';
import 'package:strack_rec/screens/main_map/helpers/navigation_flow_handler.dart';
import 'package:strack_rec/screens/main_map/helpers/recording_flow_handler.dart';

// Serveis i utilitats
import 'package:strack_rec/services/hgt_service.dart';
import 'package:strack_rec/services/altitude_logger.dart';
import 'package:strack_rec/services/gpx_import_flow.dart';
import 'package:strack_rec/services/native_barometer_channel.dart';
import 'package:strack_rec/services/permissions_service.dart';
import 'package:strack_rec/services/recording_handler.dart';
import 'package:strack_rec/theme/app_dimensions.dart';
import 'package:strack_rec/ui/app_messages.dart';
import 'package:strack_rec/utils/color_extensions.dart';
import 'package:strack_rec/utils/map_animator.dart';
import 'package:strack_rec/utils/map_layers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strack_rec/utils/distance_utils.dart';

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
  Timer? _mapStopTimer;
  Timer? _submenuAutoHideTimer;
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
  bool _showRecordingSubMenu = false;
  bool _showNavigationSubMenu = false;

  bool _isChartCollapsed = false;
  DateTime _lastMapUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _mapThrottleMs = 32;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _gpxUriSub;
  String? _lastHandledExternalGpxUri;
  bool _isHandlingExternalGpx = false;

  late MapAnimator mapAnimator;
  final double _currentMapPadding = 0;

  Future<void> _shareDebugLog() async {
    final ok = await AltitudeLoggerService().shareLog();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Log de debug compartit" : "No s'ha pogut compartir el log",
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeBarometerChannel.start();
    _loadLastPosition();
    _bindExternalGpxOpen();

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
  @override
  void dispose() {
    // 1. Treu l'observador del cicle de vida de l'aplicació
    WidgetsBinding.instance.removeObserver(this);

    // 2. Atura els sensors natius si cal
    NativeBarometerChannel.stop();
    _submenuAutoHideTimer?.cancel();
    _gpxUriSub?.cancel();

    // 3. 🛡️ NETEJA DEL MAPA: Avisem al motor natiu de MapLibre que es destrueixi immediatament
    // Això talla en sec qualsevol renderitzat, animació o descàrrega de tiles en segon pla.
    try {
      mapController?.dispose();
    } catch (e) {
      print(
        "MapLibre: Error en alliberar el controlador del mapa al dispose: $e",
      );
    }

    // 4. Finalment, destrueix el giny de Flutter de forma normal
    super.dispose();
  }

  Future<void> _bindExternalGpxOpen() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        unawaited(_handleExternalGpxUri(initialUri));
      }
    } catch (e) {
      debugPrint('Error llegint l\'intent inicial GPX: $e');
    }

    _gpxUriSub = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(_handleExternalGpxUri(uri));
      },
      onError: (Object e) {
        debugPrint('Error escoltant intents GPX: $e');
      },
    );
  }

  Future<void> _handleExternalGpxUri(Uri uri) async {
    if (!mounted || _isHandlingExternalGpx) return;

    final isContentUri = uri.scheme == 'content';
    final isFileUri = uri.scheme == 'file' || uri.scheme.isEmpty;
    if (!isContentUri && !isFileUri) return;

    final raw = uri.toString().toLowerCase();
    final isGpx =
        uri.path.toLowerCase().endsWith('.gpx') || raw.contains('.gpx');
    if (isFileUri && !isGpx) return;

    final uriKey = uri.toString();
    if (_lastHandledExternalGpxUri == uriKey) return;

    _isHandlingExternalGpx = true;
    try {
      for (int i = 0; i < 60; i++) {
        if (!mounted) return;
        if (styleInitialized && mapController != null) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      final imported = await importGpxFromUri(
        context: context,
        ref: ref,
        mapController: mapController,
        uri: uri,
      );

      if (imported) {
        _lastHandledExternalGpxUri = uriKey;
      }
    } finally {
      _isHandlingExternalGpx = false;
    }
  }

  void _cancelSubmenuAutoHideTimer() {
    _submenuAutoHideTimer?.cancel();
    _submenuAutoHideTimer = null;
  }

  void _restartSubmenuAutoHideTimerIfNeeded() {
    final bool anySubmenuOpen = _showRecordingSubMenu || _showNavigationSubMenu;
    if (!anySubmenuOpen) {
      _cancelSubmenuAutoHideTimer();
      return;
    }

    _cancelSubmenuAutoHideTimer();
    _submenuAutoHideTimer = Timer(TrackThresholds.submenuAutoHideDelay, () {
      if (!mounted) return;
      setState(() {
        _showRecordingSubMenu = false;
        _showNavigationSubMenu = false;
      });
      _cancelSubmenuAutoHideTimer();
    });
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
    // final real = ref.watch(trackRecordingProvider);
    // final imported = ref.watch(importedTrackProvider);
    // final sel = ref.watch(elevationSelectionProvider);
    // ─────────────────────────────────────────────────────────────
    // OIENT 1 RECEPTOR DE SELECCIÓ DE TRAM
    ref.listen(elevationSelectionProvider, (previous, next) async {
      if (!styleInitialized || mapController == null || !mounted) return;

      // --- la resta del teu codi de l’oient 1 ---
      final geom = MapGeometryHelper(ref: ref, mapController: mapController);

      final bool isRecording =
          ref.read(trackRecordingProvider).recordingState ==
          RecordingState.recording;

      final List<List<double>> coordsActuales = isRecording
          ? ref.read(trackRecordingProvider).coordinates
          : ref.read(importedTrackProvider.notifier).visibleCoordinates;

      try {
        await updateSelectionCircles(mapController!, next, coordsActuales);
        if (!mounted) return;

        updateSelectedSegmentGeometry(mapController!, next, coordsActuales);

        if (next.mapToolState == MapSelectionToolState.selected) {
          updateSelectedSegmentGeometry(mapController!, next, coordsActuales);
        }

        if (!mounted) return;
        await setChartInteractionGeometry(
          mapController!,
          rangeStartCoords: geom.getCoordsFromGlobalIndex(
            next.startTrackIndex ?? next.singlePointIndex,
          ),
          rangeEndCoords: geom.getCoordsFromGlobalIndex(next.endTrackIndex),
          hoverCoords: null,
        );
      } catch (_) {}
    });

    // 🛰️ OIENT 3: POSICIÓ DE L’USUARI (BLINDAT)
    ref.listen<UserPosition?>(locationProvider, (prev, next) async {
      // 🛡️ CONTROL INICIAL: Afegim !mounted
      if (!styleInitialized ||
          mapController == null ||
          next == null ||
          !mounted) {
        return;
      }

      final recState = ref.read(trackRecordingProvider).recordingState;

      try {
        if (recState != RecordingState.recording) {
          // Canviem ! per ?. per a màxima seguretat de punters
          await mapController?.setGeoJsonSource("user_location", {
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

          // 🛡️ Re-comprovem abans d'animar la posició de l'usuari
          if (!mounted) return;
          mapAnimator.animateUserPosition(
            next.position,
            bottomPadding: _currentMapPadding,
          );
        }
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat error de JNI en actualitzar posició d'usuari: ${e.message}",
        );
      }

      final ara = DateTime.now();
      if (ara.difference(_lastPrefsSave).inMinutes >= 5) {
        _savePositionToPrefs();
      }

      if (isImportingGpx) return;

      final bool isRealSignal = next.accuracy < 100.0;

      if (!hasDoneFirstFixZoom && isRealSignal) {
        if (!mounted) return; // 🛡️ Seguretat abans del setState
        setState(() {
          hasDoneFirstFixZoom = true;
          isProgrammaticMove = true;
          _lastCameraCenter = next.position;
        });

        try {
          safeAnimateCamera(CameraUpdate.newLatLngZoom(next.position, 16.0));
        } catch (e) {
          print(
            "MapLibre: Ignorada animació de càmera inicial (pantalla tancada)",
          );
        }

        // 🛡️ PROTECCIÓ DEL RETARD DE 300MS
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
          if (!mounted) return; // 🛡️ Seguretat abans del setState
          setState(() {
            isProgrammaticMove = true;
            _lastCameraCenter = next.position;
          });

          try {
            safeAnimateCamera(CameraUpdate.newLatLng(next.position));
          } catch (e) {
            print(
              "MapLibre: Ignorada animació de seguiment intel·ligent (pantalla tancada)",
            );
          }

          // 🛡️ PROTECCIÓ DEL RETARD DE 600MS
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => isProgrammaticMove = false);
            }
          });
        }
      }
    });

    // 📊 OIENT 4: GRAVACIÓ FÍSICA (BLINDAT)
    ref.listen<Track>(trackRecordingProvider, (prev, next) {
      // 🛡️ CONTROL INICIAL: Afegim la comprovació de cicle de vida !mounted
      if (!styleInitialized || mapController == null || !mounted) return;
      // 🗑️ El track s'ha eliminat
      if (next.points.isEmpty) {
        mapController!.setGeoJsonSource("track_line", {
          "type": "FeatureCollection",
          "features": [],
        });
        return;
      }
      try {
        if (next.recordingState == RecordingState.recording) {
          mapAnimator.updateFromTrack(next, !smartCenterEnabled);
        }
      } catch (e) {
        print(
          "MapLibre: Error en actualitzar l'animació de la ruta gravada: $e",
        );
      }

      if (isImportingGpx) return;

      final bool isRecoveringTrack =
          (prev == null || prev.points.isEmpty) &&
          next.points.length > 1 &&
          !hasDoneRecoveryFit;

      if (isRecoveringTrack) {
        hasDoneRecoveryFit = true;
        // final padding = _computeMapPadding(context, true);

        // 🛡️ Protegim l'ajust de zoom a la pantalla (fitToBounds)
        try {
          if (!mounted) return; // Re-comprovació abans de moure la càmera
          MapGeometryHelper(ref: ref, mapController: mapController).fitToBounds(
            next.coordinates,
            instant: true,
            left: 40,
            right: 40,
            // top: padding.top,
            // bottom: padding.bottom,
          );
        } catch (e) {
          print(
            "MapLibre: No s'han pogut enquadrar els límits de la ruta recuperada: $e",
          );
        }
      }
    });

    // OIENT 5: TRACK IMPORTAT (BLINDAT)
    // OIENT 5: TRACK IMPORTAT (BLINDAT CONTRA INTERFERÈNCIES DE SELECCIÓ)
    ref.listen<Track?>(importedTrackProvider, (prev, next) {
      // 🛡️ CONTROL INICIAL: Evitem l'execució si la pantalla ja no està muntada
      if (!styleInitialized || mapController == null || !mounted) return;

      // 🔍 LLEGIM SI L'EINA DE SELECCIÓ ESTÀ APAGADA AMB EL RECEPTOR DIRECTE
      final selection = ref.read(elevationSelectionProvider);
      final bool isToolOff =
          selection.mapToolState == MapSelectionToolState.off;

      // 🔥 MOSTRAR AUTOMÀTICAMENT EL PANELL D’ELEVACIONS
      // 🚀 MODIFICACIÓ CLAU: Només forcem l'obertura del gràfic si hi ha ruta
      // I ÚNICAMENT si l'eina de selecció de trams està apagada.
      if (next != null && next.coordinates.isNotEmpty && isToolOff) {
        if (mounted) setState(() => _isChartCollapsed = false);
      }

      if (next == null) {
        if (mounted) {
          setState(() {
            selectedIndexGraph = null;
            selectedIndexStart = null;
            selectedIndexEnd = null;
          });
        }

        try {
          // Canviem ! per ?. per seguretat de memòria
          mapController?.setGeoJsonSource("imported_track", {
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
        try {
          mapController?.setGeoJsonSource("imported_track", {
            "type": "FeatureCollection",
            "features": [],
          });
        } catch (_) {}
        return;
      }

      // 🛡️ Encapsulem les crides natives del mapa en un try/catch segur
      try {
        mapController?.setGeoJsonSource("imported_track", {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {"type": "LineString", "coordinates": coordsVisibles},
            },
          ],
        });

        if (!mounted) return; // Seguretat abans de llegir propietats visuals
        final importedSettings = ref.read(importedTrackSettingsProvider);

        mapController?.setLayerProperties(
          "imported_track_layer",
          LineLayerProperties(
            lineColor: importedSettings.color.toMapLibreColor(),
            lineWidth: importedSettings.width,
            lineCap: "round",
            lineJoin: "round",
          ),
        );

        if (isImportingGpx && next.coordinates.isNotEmpty) {
          if (!mounted) return;
          MapGeometryHelper(
            ref: ref,
            mapController: mapController,
          ).fitToBounds(next.coordinates, left: 40, right: 40);
        }
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat error de renderitzat del track importat: ${e.message}",
        );
      } catch (e) {
        print("Error inesperat en processar el track importat: $e");
      }
    });

    // OIENT 6: WAYPOINTS GRAVATS (BLINDAT)
    ref.listen(waypointsProvider, (prev, next) async {
      // 🛡️ CONTROL INICIAL: Evitem l'execució si el giny ja s'està destruint
      if (!styleInitialized ||
          !waypointLayersReady ||
          mapController == null ||
          !mounted) {
        return;
      }

      try {
        // Actualitzem la font de dades fent servir el controlador de forma segura
        updateWaypointSource(mapController!, 'waypoints_recorded_source', next);

        // 🛡️ Re-comprovació de cicle de vida abans d'iniciar l'animació asíncrona
        if (!mounted) return;

        await animateWaypointAppearance(
          mapController!,
          'waypoints_recorded_layer',
        );

        // 🛡️ RE-COMPROVACIÓ CRÍTICA: Després de l'await, comprovem si seguim vius a la pantalla
        if (!mounted) return;
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat crash asíncron a l'animació de waypoints gravats: ${e.message}",
        );
      } catch (e) {
        print("Error en el flux d'animació de waypoints gravats: $e");
      }
    });

    // OIENT 7: WAYPOINTS IMPORTATS (BLINDAT)
    ref.listen(importedWaypointsProvider, (prev, next) async {
      // 🛡️ CONTROL INICIAL: Evitem l'execució si el giny ja s'està destruint o tancant
      if (!styleInitialized ||
          !waypointLayersReady ||
          mapController == null ||
          !mounted) {
        return;
      }

      try {
        // Actualitzem la font de dades dels punts de pas importats de manera segura
        updateWaypointSource(mapController!, 'waypoints_imported_source', next);

        // 🛡️ Re-comprovació de cicle de vida abans d'iniciar l'animació asíncrona
        if (!mounted) return;

        await animateWaypointAppearance(
          mapController!,
          'waypoints_imported_layer',
        );

        // 🛡️ RE-COMPROVACIÓ CRÍTICA: Després de l'await, comprovem si seguim vius a la pantalla
        if (!mounted) return;
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat crash asíncron a l'animació de waypoints importats: ${e.message}",
        );
      } catch (e) {
        print("Error en el flux d'animació de waypoints importats: $e");
      }
    });

    // OIENT 8
    ref.listen(trackSettingsProvider, (previous, next) {
      // 🛡️ CONTROL INICIAL: Evitem l'execució si la pantalla s'està destruint
      if (mapController == null || !styleInitialized || !mounted) return;

      // 🛡️ Encapsulem els canvis de propietats natius en un try/catch segur
      try {
        mapController?.setLayerProperties(
          "track_line_layer",
          LineLayerProperties(
            lineColor: next.color.toMapLibreColor(),
            lineWidth: next.width,
            lineCap: "round",
            lineJoin: "round",
          ),
        );
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat error al canviar els ajustos de capa (pantalla tancada): ${e.message}",
        );
      } catch (e) {
        print("Error inesperat en aplicar els ajustos del track: $e");
      }
    });

    // OIENT 9
    ref.listen(importedTrackSettingsProvider, (previous, next) {
      // 🛡️ CONTROL INICIAL: Evitem l'execució si la pantalla ja no està muntada
      if (!styleInitialized || mapController == null || !mounted) return;

      // 🛡️ Encapsulem les modificacions de capa en un try/catch de seguretat
      try {
        mapController?.setLayerProperties(
          "imported_track_layer",
          LineLayerProperties(
            lineColor: next.color.toMapLibreColor(),
            lineWidth: next.width,
            lineCap: "round",
            lineJoin: "round",
          ),
        );
      } on PlatformException catch (e) {
        print(
          "MapLibre: Evitat error al canviar els ajustos de la capa importada: ${e.message}",
        );
      } catch (e) {
        print("Error inesperat en aplicar els ajustos del track importat: $e");
      }
    });

    // OIENT 10: ALERTES I DIÀLEGS
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      // 🛡️ CONTROL INICIAL CRÍTIC: Si la pantalla s'ha tancat, no podem utilitzar el 'context'
      if (!mounted) return;

      if (next.showBackOnTrackSnackbar == true) {
        // 🛡️ Mostrem el snackbar de forma segura
        AppMessages.showBackOnTrackPersistentSnackbar(context, ref);

        // 🛡️ Re-comprovem que seguim muntats abans de modificar un altre provider de fons
        if (!mounted) return;
        ref.read(navigationProvider.notifier).dismissBackOnTrackAlert();
      }
    });

    // OIENT 11 DIÀLEG INTERACTIU DE RUMB INVERS
    ref.listen<NavigationState>(navigationProvider, (prev, next) async {
      // 🛡️ CONTROL INICIAL CRÍTIC: Si la pantalla s'ha tancat, avortem
      if (!mounted) return;

      // Només actuem si el motor demana el diàleg i la UI no el té ja obert
      if (next.showReverseTrackDialog && !_isShowingReverseDialog) {
        _isShowingReverseDialog = true;

        // 🛡️ Guardem el resultat del diàleg envoltat de seguretat
        bool? accept;
        try {
          // El diàleg s'obrirà només quan l'app estigui en foreground.
          // Si està en background, s'esperarà aquí de forma segura sense congelar el so.
          accept = await AppMessages.showReverseTrackDialog(context);
        } catch (e) {
          print("Error al mostrar el diàleg de ruta inversa: $e");
          _isShowingReverseDialog = false;
          return;
        }

        // 🛡️ RE-COMPROVACIÓ POST-AWAIT: L'usuari ha pogut tancar la pantalla mentre mirava el diàleg
        if (!mounted) return;

        if (accept == true) {
          ref.read(navigationProvider.notifier).reverseImportedTrack();
        } else {
          ref.read(navigationProvider.notifier).dismissReverseTrackDialog();
        }

        // Alliberem el control local de la UI
        _isShowingReverseDialog = false;
      }
    });

    // OIENT 12
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      // 🛡️ CONTROL INICIAL CRÍTIC: Si la pantalla ja no existeix, evitem utilitzar el context
      if (!mounted) return;

      if (next.showEndOfTrackSnackbar == true) {
        // 🛡️ Mostrem el snackbar de forma segura
        AppMessages.showEndOfTrackSnackBar(context);

        // 🛡️ Re-comprovem que seguim vius abans de demanar un canvi d'estat al provider
        if (!mounted) return;
        ref.read(navigationProvider.notifier).dismissEndOfTrackAlert();
      }
    });

    // OIENT 13
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      // 🛡️ CONTROL INICIAL CRÍTIC: Si la pantalla ja no està muntada, avortem per protegir el context
      if (!mounted) return;

      if (next.showOffTrackSnackbar == true) {
        // 🛡️ Mostrem el snackbar persistent de manera segura
        AppMessages.showOffTrackPersistentSnackbar(context, ref);

        // 🛡️ Re-comprovem que seguim vius a la pantalla abans de demanar el canvi d'estat
        if (!mounted) return;
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
                onShareLog: _shareDebugLog,
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
                      // 1. Amaguem el botó flotant central síncronament a l'instant de bellugar
                      ref
                          .read(elevationSelectionProvider.notifier)
                          .hideSelectionButton();

                      // 3. Actualitzem els proveïdors de posició del mapa
                      ref
                          .read(mapBearingProvider.notifier)
                          .update(position.bearing);
                      ref.read(mapZoomProvider.notifier).update(position.zoom);
                      ref
                          .read(mapCenterLatProvider.notifier)
                          .update(position.target.latitude);
                      ref
                          .read(mapCenterLonProvider.notifier)
                          .update(position.target.longitude);

                      // 4. Control de rendiment per no saturar la CPU (Throttle)
                      final ara = DateTime.now();
                      if (ara.difference(_lastMapUpdateTime).inMilliseconds >
                          _mapThrottleMs) {
                        _lastMapUpdateTime = ara;

                        final sel = ref.read(elevationSelectionProvider);

                        // 🚀 L'IMANT GEOMÈTRIC EN UNA SOLA LÍNIA REUSABLE PROTEGIT:
                        // Només s'executa si l'eina busca inici/final I si la font és el moviment real del mapa
                        if ((sel.mapToolState ==
                                    MapSelectionToolState.selectingStart ||
                                sel.mapToolState ==
                                    MapSelectionToolState.selectingEnd) &&
                            sel.source == SelectionSource.map) {
                          ElevationMagnetHelper.recalcularIActualitzar(
                            ref: ref,
                            mapController: mapController!,
                          );
                        }
                      }
                    },

                    onCameraIdle: () {
                      _mapStopTimer?.cancel();
                      _mapStopTimer = Timer(
                        const Duration(milliseconds: 180),
                        () {
                          if (mounted) {
                            ref
                                .read(elevationSelectionProvider.notifier)
                                .showSelectionButton();
                          }
                        },
                      );
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

                      // 1. Damos de alta todas las fuentes y capas base en la GPU nativa
                      await setupUserLocationLayer(mapController!);
                      await setupWaypointLayers(mapController!);

                      // 🚀 CORRECCIÓ DEFINITIVA 1 (Ruta gravada):
                      // Creem un objecte LineLayerProperties real tal com demana MapLibre.
                      // Forcem que el color sigui una String vàlida i el gruix un double de Dart.
                      final String trackColorHex =
                          trackSettings.color.toMapLibreColor().isNotEmpty
                          ? trackSettings.color.toMapLibreColor()
                          : "#FF0000";

                      await mapController!.setLayerProperties(
                        "track_line_layer",
                        LineLayerProperties(
                          lineColor: trackColorHex,
                          lineWidth: trackSettings.width
                              .toDouble(), // 🎯 Forcem double pur!
                        ),
                      );

                      // 🚀 CORRECCIÓ DEFINITIVA 2 (Ruta importada):
                      final String importedColorHex =
                          importedSettings.color.toMapLibreColor().isNotEmpty
                          ? importedSettings.color.toMapLibreColor()
                          : "#00A8E8";

                      await mapController!.setLayerProperties(
                        "imported_track_layer",
                        LineLayerProperties(
                          lineColor: importedColorHex,
                          lineWidth: importedSettings.width
                              .toDouble(), // 🎯 Forcem double pur!
                        ),
                      );

                      // 🚀 CLAVE DE SINCRONIZACIÓN:
                      // Solo cuando la GPU ha terminado de procesar absolutamente todo el estilo,
                      // abrimos las puertas de la interfaz para que el listener de Riverpod pueda operar de forma segura.
                      setState(() {
                        waypointLayersReady = true;
                        styleInitialized = true;
                      });
                    },
                  ),

                  // 🎯 CAPA 2: RETICLE CENTRAL AUTOMÀTIC I BOTÓ DE SELECCIÓ (SENSE PARPELLEIGS)
                  Consumer(
                    builder: (context, ref, _) {
                      final sel = ref.watch(elevationSelectionProvider);

                      // 🚀 CONDICIÓ BLINDADA: La retícula es mostra SIEMPRE que l'eina estigui activa i en mode reticle.
                      // Ignorem totalment si 'showCenterButton' és true o false mentre es mou el mapa!
                      final bool showReticleVisual =
                          sel.selectionMode == MapSelectionMode.reticle &&
                          (sel.mapToolState ==
                                  MapSelectionToolState.selectingStart ||
                              sel.mapToolState ==
                                  MapSelectionToolState.selectingEnd ||
                              sel.mapToolState ==
                                  MapSelectionToolState.selected);

                      if (!showReticleVisual) return const SizedBox.shrink();

                      // Mantenim exactament la teva lògica de colors original de STrack Rec
                      final bool isStartOrSelected =
                          sel.mapToolState ==
                              MapSelectionToolState.selectingStart ||
                          sel.mapToolState == MapSelectionToolState.selected;

                      final Color reticleColor = isStartOrSelected
                          ? const Color(0xFF4CAF50) // 🟢 Verd per a l'Inici
                          : const Color(0xFFF44336); // 🔴 Vermell per al Final

                      return Positioned.fill(
                        child: Stack(
                          children: [
                            // 1. EL VISOR CENTRAL PERSONALITZAT (S'immunitza contra el moviment del mapa)
                            IgnorePointer(
                              ignoring: true,
                              child: Positioned.fill(
                                child: MapFullScreenReticle(
                                  color: reticleColor,
                                ),
                              ),
                            ),

                            // 2. EL BOTÓ FLOTANT DE CONFIRMACIÓ (Aquest sí que respon a showCenterButton)
                            if (sel.showCenterButton == true)
                              Align(
                                alignment: Alignment.center,
                                child: Transform.translate(
                                  offset: const Offset(0, -60),
                                  child: Material(
                                    elevation: 6,
                                    shadowColor: Colors.black38,
                                    borderRadius: BorderRadius.circular(20),
                                    color: reticleColor,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        // Mantenim exactament el teu codi d'onTap original intacte de STrack Rec...
                                        final centerLat = ref.read(
                                          mapCenterLatProvider,
                                        );
                                        final centerLon = ref.read(
                                          mapCenterLonProvider,
                                        );
                                        final imported = ref.read(
                                          importedTrackProvider,
                                        );
                                        final real = ref.read(
                                          trackRecordingProvider,
                                        );

                                        final coords =
                                            (real.recordingState ==
                                                RecordingState.recording)
                                            ? real.coordinates
                                            : imported?.coordinates ?? [];

                                        if (coords.isEmpty) return;

                                        int nearestIndex = 0;
                                        double minDist = double.infinity;
                                        for (
                                          int i = 0;
                                          i < coords.length;
                                          i++
                                        ) {
                                          final dLat = coords[i][1] - centerLat;
                                          final dLon = coords[i][0] - centerLon;
                                          final dist =
                                              dLat * dLat + dLon * dLon;
                                          if (dist < minDist) {
                                            minDist = dist;
                                            nearestIndex = i;
                                          }
                                        }

                                        final notifier = ref.read(
                                          elevationSelectionProvider.notifier,
                                        );

                                        if (sel.mapToolState ==
                                            MapSelectionToolState.selected) {
                                          notifier.iniciarNouTramDesDeSelected(
                                            nearestIndex,
                                          );
                                        } else if (sel.mapToolState ==
                                            MapSelectionToolState
                                                .selectingStart) {
                                          notifier.fixStartFromMap(
                                            nearestIndex,
                                          );
                                        } else if (sel.mapToolState ==
                                            MapSelectionToolState
                                                .selectingEnd) {
                                          notifier.fixEndFromMap(nearestIndex);
                                        }

                                        notifier.hideSelectionButton();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isStartOrSelected
                                                  ? Icons.play_arrow
                                                  : Icons.flag,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isStartOrSelected
                                                  ? AppLocalizations.of(
                                                          context,
                                                        )!
                                                        .fixStart // 🟢 "Fixar inici"
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.fixEnd, // 🔴 "Fixar fi"
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 🎛️ HUD SUPERIOR (es manté igual)
                  if (!_fullScreen)
                    MapTopControls(
                      mapController: mapController,
                      smartCenterEnabled: smartCenterEnabled,
                      onCenterOnUser: _centerOnUser,
                      onAddWaypoint: () => _onAddWaypoint(context, ref),
                    ),

                  // CAPA 4: EL MODUL DE GRAFICS I ESTADÍSTIQUES FIXES
                  MapElevationHud(
                    isChartCollapsed: _isChartCollapsed,
                    onCollapseChanged: (collapsed) {
                      setState(() => _isChartCollapsed = collapsed);
                    },
                  ),

                  MapScissorsButtons(
                    isChartCollapsed: _isChartCollapsed,
                    mapController: mapController,
                    onCollapseChanged: (collapsed) {
                      setState(() => _isChartCollapsed = collapsed);
                    },
                  ),

                  // RECORDING SUB MENU
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom: _showRecordingSubMenu ? 20 : -200,
                    child: Center(
                      child: RecordingSubMenu(
                        state: ref.watch(trackRecordingProvider).recordingState,
                        onAction: (action) {
                          _cancelSubmenuAutoHideTimer();
                          setState(() => _showRecordingSubMenu = false);
                          _openRecordingControl(context, ref, action);
                        },
                        onClose: () {
                          _cancelSubmenuAutoHideTimer();
                          setState(() => _showRecordingSubMenu = false);
                        },
                      ),
                    ),
                  ),

                  // NAVIGATION SUB MENU
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom: _showNavigationSubMenu ? 20 : -200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.subMenuHorizontalPadding,
                      ),
                      child: NavigationSubMenu(
                        navState: ref.watch(navigationProvider),
                        hasTrack:
                            ref
                                .watch(importedTrackProvider)
                                ?.coordinates
                                .isNotEmpty ??
                            false,
                        onAction: (bool val) {
                          _cancelSubmenuAutoHideTimer();
                          setState(() => _showNavigationSubMenu = false);
                          _handleSendaNavigationAction(
                            val
                                ? (ref.read(navigationProvider).isFollowing
                                      ? "toggle_pause"
                                      : "follow")
                                : (ref.read(navigationProvider).isFollowing
                                      ? "stop_follow"
                                      : "clear_imported"),
                          );
                        },
                        onClose: () {
                          _cancelSubmenuAutoHideTimer();
                          setState(() => _showNavigationSubMenu = false);
                        },
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
                },

                // 🔥 NOU
                onToggleRecordingSubmenu: () {
                  setState(() {
                    _showRecordingSubMenu = !_showRecordingSubMenu;
                    _showNavigationSubMenu = false;
                  });
                  _restartSubmenuAutoHideTimerIfNeeded();
                },

                // 🔥 NOU
                onToggleNavigationSubmenu: () {
                  final hasTrack =
                      ref.read(importedTrackProvider)?.coordinates.isNotEmpty ??
                      false;

                  if (!hasTrack) {
                    _cancelSubmenuAutoHideTimer();
                    _openNavigationControl(context, ref, false);
                    return;
                  }

                  setState(() {
                    _showNavigationSubMenu = !_showNavigationSubMenu;
                    _showRecordingSubMenu = false;
                  });
                  _restartSubmenuAutoHideTimerIfNeeded();
                },
              ),
          ],
        ),
      ),
    );
  }

  // 🏁 EXECUTOR RECEPTOR DE LA MÀQUINA D'ESTATS SEQÜENCIAL DE STrack Rec
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
}
