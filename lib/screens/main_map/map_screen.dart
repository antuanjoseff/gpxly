// lib/screens/map/map_screen.dart (BLOC 1 DE 2)
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';

// Notifiers natius de Senda
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/providers/barometer_provider.dart';

// Widgets independents que hem separat
import 'package:senda/screens/main_map/widgets/map_app_bar.dart';
import 'package:senda/screens/main_map/widgets/map_base_layer.dart';
import 'package:senda/screens/main_map/widgets/map_bottom_controls.dart';
import 'package:senda/screens/main_map/widgets/map_top_controls.dart';
import 'package:senda/screens/main_map/widgets/senda_brand_label.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/range_info_panel.dart';
import 'package:senda/widgets/embedded_elevation_profile.dart';

// Els 3 HELPERS d'extracció de codi massiu
import 'package:senda/screens/main_map/helpers/map_geometry_helper.dart';
import 'package:senda/screens/main_map/helpers/navigation_flow_handler.dart';
import 'package:senda/screens/main_map/helpers/recording_flow_handler.dart';

// Serveis i Utilitats
import 'package:senda/services/hgt_service.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/services/recording_handler.dart';
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

  // Índexs de la interacció del perfil d'elevacions
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? selectedIndexGraph;
  int? _prevWpIndex;
  int? _lastWpIndex;
  bool _isChartCollapsed = false;
  DateTime _lastMapUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _mapThrottleMs = 32;
  late MapAnimator mapAnimator;

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

    // 🛡️ OBLIGATORI: Reactivar el Smart Center des del botó
    setState(() {
      _lastCameraCenter = null; // Força el recàlcul de distància des de zero
      smartCenterEnabled = true; // Torna a activar el mode automàtic
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

  // 🚀 PUENT DE SEGURETAT DE GRAVACIÓ DIRECTE AMB EL PROPI FLOW_HANDLER
  void _openRecordingControl(BuildContext context, WidgetRef ref) {
    RecordingFlowHandler(ref: ref, context: context).openRecordingControl(
      mapController: mapController,
      onToggleSmartCenter: (val) => setState(() => smartCenterEnabled = val),
      onUpdateLastCamera: (pos) => _lastCameraCenter = pos,
      // 🛡️ REGLA D'OR SENDA: Forcem que el gràfic d'elevacions arrenqui minimitzat (true)
      // i acompanyi l'efecte ascensor del botó de forma neta des de l'inici.
      onToggleProgrammaticMove: (val) {
        setState(() {
          isProgrammaticMove = val;
          _isChartCollapsed = true;
        });
      },
      safeAnimateCamera: safeAnimateCamera,
    );
  }

  // 🧭 PONT DE NAVEGACIÓ CRÍTIC AMB COMPROVACIÓ PROACTIVA DE PERMISOS
  void _openNavigationControl(
    BuildContext context,
    WidgetRef ref,
    bool hasTrack,
  ) async {
    final navigationState = ref.read(navigationProvider);

    // 🛡️ REGLA D'OR SENDA: Si hi ha un track a la pantalla però encara NO l'estem seguint,
    // interceptem el clic per assegurar síncronament els permisos de segon pla amb el diàleg.
    if (hasTrack && !navigationState.isFollowing) {
      final bool permisosConcedidos =
          await PermissionsService.ensureBackgroundLocationWithDialog(context);

      // Si l'usuari denega els permisos de localització al diàleg, frenem el flux a l'acte
      if (!permisosConcedidos) {
        debugPrint(
          "🧭 [SENDA] flux de navegació detingut: Permisos de segon pla denegats.",
        );
        return;
      }
    }

    // Si els permisos ja estaven atorgats d'origen (o l'usuari els acaba d'acceptar),
    // o si el botó actua en mode "importar fitxer GPX" (hasTrack == false), deleguem al Handler.
    if (mounted) {
      NavigationFlowHandler(ref: ref, context: context).openNavigationControl(
        mapController: mapController,
        hasImportedTrack: hasTrack,
        fitToBounds: (coords, {instant = false}) => MapGeometryHelper(
          ref: ref,
          mapController: mapController,
        ).fitToBounds(coords, instant: instant),
      );
    }
  }

  // Estil unificat obligatori dels teus botons visuals de l'Stack
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

  // Creador autònom de Fites Senda
  void _onAddWaypoint(BuildContext context, WidgetRef ref) async {
    final recordingTrack = ref.read(trackRecordingProvider);
    if (recordingTrack.points.isEmpty) return;

    final lastPoint = recordingTrack.points.last;
    final lastLat = lastPoint.position.latitude;
    final lastLon = lastPoint.position.longitude;
    final lastAlt = lastPoint.altitude;

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
      trackIndex: recordingTrack.points.length - 1,
      ele: correctedAlt,
      distanceAtPoint: recordingTrack.distance,
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

    // ─────────────────────────────────────────────────────────────────────────
    // 🟢 COGNICIÓ DE SELECCIÓ (Gràfic visible i obert):
    // ─────────────────────────────────────────────────────────────────────────
    if (!_isChartCollapsed) {
      final currentSelection = ref.read(elevationSelectionProvider);

      // 📐 REGLA A: EL TRAM JA HA ESTAT INICIAT (Mode Range per Long Press previ)
      if (currentSelection.mode == SelectionMode.range) {
        final Set<int> allWpIndexes = [
          ...recorded,
          ...imported,
        ].map((w) => w.trackIndex).toSet();

        // Modifiquem el tram utilitzant la màquina d'estats del Notifier
        ref
            .read(elevationSelectionProvider.notifier)
            .toggleWaypoint(wpTrackIndex, allWpIndexes);

        return; // 🛑 Sortim: Modificació de tram feta, no mostrem diàleg.
      }
      // 📐 REGLA B: NO HI HA CAP TRAM INICIAT (Mode Single / Pintem punt verd d'inspecció)
      else {
        // Cridem el mètode de Riverpod. L'oient superior s'encarregarà de pintar el punt verd automàticament.
        ref
            .read(elevationSelectionProvider.notifier)
            .setSinglePoint(wpTrackIndex);

        return; // 🛑 Sortim: Punt col·locat amb èxit, evitem diàleg informatiu.
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ℹ️ DIÀLEG ORDINARI (Només si el gràfic està tancat / minimitzat)
    // ─────────────────────────────────────────────────────────────────────────
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

    // 📊 LECTURA D'ESTATS REACTIUS DE LA INTERFÍCIE (HUD / APPBAR)
    final pressure = ref.watch(barometerProvider).value;
    final isRunning = ref.watch(locationProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(locationProvider.notifier).isSimulationPaused;
    final trackSettings = ref.watch(trackSettingsProvider);

    // ─────────────────────────────────────────────────────────────
    // 🛡️ RECEPTORS I OIENTS DE SEGUIDAMENT ASÍNCRON
    // ─────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    // 🛡️ RECEPTORS I OIENTS DE SEGUIDAMENT ASÍNCRON (A map_screen.dart)
    // ─────────────────────────────────────────────────────────────────────────
    ref.listen(elevationSelectionProvider, (previous, next) {
      if (!_isChartCollapsed && mapController != null && styleInitialized) {
        final geom = MapGeometryHelper(ref: ref, mapController: mapController);

        // Determinem quin és l'índex d'inici real: el de tram o el del punt únic
        final int? indexIniciUnificat =
            next.startTrackIndex ?? next.singlePointIndex;

        setChartInteractionGeometry(
          mapController!,
          // 🟢 ARA EL PUNT VERD s'il·lumina tant per a punts únics com per a inici de trams
          rangeStartCoords: geom.getCoordsFromGlobalIndex(indexIniciUnificat),
          rangeEndCoords: geom.getCoordsFromGlobalIndex(next.endTrackIndex),
          // 🚫 El taronja (hoverCoords) es passa a null de manera permanent perquè quedi desactivat
          hoverCoords: null,
        );
      }
    });

    ref.listen<UserPosition?>(locationProvider, (prev, next) async {
      if (!styleInitialized || mapController == null || next == null) return;

      mapAnimator.animateUserPosition(next.position);

      final ara = DateTime.now();
      if (ara.difference(_lastPrefsSave).inMinutes >= 5) {
        _savePositionToPrefs();
      }

      if (isImportingGpx) return;

      final recordingPoints = ref.read(trackRecordingProvider).points;
      if (prev == null && recordingPoints.isEmpty) {
        // 🔥 CORRECCIÓ 1: setState per al primer posicionament net a l'iniciar l'app
        setState(() {
          hasDoneFirstFixZoom = true;
          isProgrammaticMove = true;
          _lastCameraCenter = next.position;
        });

        safeAnimateCamera(CameraUpdate.newLatLngZoom(next.position, 18));

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              isProgrammaticMove = false;
            });
          }
        });
        return;
      }

      if (smartCenterEnabled && !isProgrammaticMove) {
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
          // 🔥 CORRECCIÓ 2: setState synchronous obligatori abans de moure la càmera.
          // D'aquesta manera el Listener de MapBaseLayer s'assabenta a l'acte i no falla.
          setState(() {
            isProgrammaticMove = true;
            _lastCameraCenter = next.position;
          });

          safeAnimateCamera(CameraUpdate.newLatLng(next.position));

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                isProgrammaticMove = false;
              });
            }
          });
        }
      }
    });

    // OIENT 2: GRAVACIÓ FÍSICA (LÍNIA I TRAMS ANIMATS UNIFICATS)
    ref.listen<Track>(trackRecordingProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;
      mapAnimator.updateFromTrack(next, !smartCenterEnabled);

      if (isImportingGpx) return;

      final bool isRecoveringTrack =
          (prev == null || prev.points.isEmpty) &&
          next.points.length > 1 &&
          !hasDoneRecoveryFit;

      if (isRecoveringTrack) {
        hasDoneRecoveryFit = true;

        MapGeometryHelper(
          ref: ref,
          mapController: mapController,
        ).fitToBounds(next.coordinates, instant: true);
      }
    });

    // OIENT 3: SET DE CAPES DEL TRACK IMPORTAT (GPX PROGRESSIU)
    ref.listen<Track?>(importedTrackProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

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
        } catch (e) {
          debugPrint("⚠️ Error al netejar geometries en eliminar track: $e");
        }
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
        MapGeometryHelper(
          ref: ref,
          mapController: mapController,
        ).fitToBounds(next.coordinates);
      }
    });

    // OIENT 4: RECEPTORS DE REFRESC DE LES CAPES DE WAYPOINTS
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

    // OIENT 5: ESTILS VISUALS DE CAPA
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

    // OIENT 6: GESTIÓ D'ALERTES I DIÀLEGS EN PANTALLA
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      if (next.showBackOnTrackSnackbar == true) {
        AppMessages.showBackOnTrackPersistentSnackbar(context, ref);
        ref.read(navigationProvider.notifier).dismissBackOnTrackAlert();
      }
    });

    ref.listen<NavigationState>(navigationProvider, (prev, next) async {
      if (next.showReverseTrackDialog && !_isShowingReverseDialog) {
        _isShowingReverseDialog = true;
        ref.read(navigationProvider.notifier).sounds.playReversedTrackSound();
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

    // 📐 CONTROL DE CÀRREGA DE SEGURETAT DE LA CÀMERA
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
        // 🚀 COMPONENT EXTRET 1: Barra superior d'eines i configuració
        appBar: _fullScreen
            ? null
            : MapAppBar(
                pressure: pressure,
                isRunning: isRunning,
                isPaused: isPaused,
              ),
        body: Stack(
          children: [
            // 🗺️ CAPA 1: COMPONENT EXTRET 2: Visor del mapa MapLibre (Aïllat)
            MapBaseLayer(
              initialCameraTarget: _initialCameraTarget!,
              initialZoom: _initialZoom,
              smartCenterEnabled: smartCenterEnabled,
              isProgrammaticMove: isProgrammaticMove,
              isFullScreen: _fullScreen,
              onSmartCenterChanged: (val) =>
                  setState(() => smartCenterEnabled = val),
              onFullScreenChanged: (val) => setState(() => _fullScreen = val),

              onMapCreated: (controller) {
                mapController = controller;
                mapAnimator = MapAnimator(controller); // Unificat de forma neta
                controller.onFeatureTapped.add(_onFeatureTapped);
              },
              onStyleLoaded: () async {
                await setupUserLocationLayer(mapController!);
                await setupWaypointLayers(mapController!);

                setState(() {
                  waypointLayersReady = true;
                  styleInitialized = true;
                });

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

            // 🏷️ Marca d'aigua de Senda a la cantonada superior
            const Positioned(top: 10, left: 12, child: SendaBrandLabel()),

            // 🎛️ CAPA 2: INTERFÍCIE FLOTANT HUD (Només si no està en fullScreen)
            if (!_fullScreen) ...[
              // 🚀 COMPONENT EXTRET 3: Píndola de temps i controls de dalt a la dreta
              MapTopControls(
                mapController: mapController,
                smartCenterEnabled: smartCenterEnabled,
                onCenterOnUser: _centerOnUser,
                onAddWaypoint: () => _onAddWaypoint(context, ref),
              ),

              // 🚀 COMPONENT EXTRET 4: Botons d'acció inferiors amb moviment d'ascensor
              MapBottomControls(
                isChartCollapsed: _isChartCollapsed,
                systemBottomPadding: systemBottomPadding,
                onAddWaypoint: () => _onAddWaypoint(context, ref),
                onOpenRecordingControl: () =>
                    _openRecordingControl(context, ref),
                onOpenNavigationControl: (hasTrack) =>
                    _openNavigationControl(context, ref, hasTrack),
                onHandleNavigationAction: _handleSendaNavigationAction,
              ),

              // 📈 ELEMENT FLOTANT: Perfil d'elevació basat en Riverpod (SENSE CALLBACKS NI PARÀMETRES VELLS)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  child: EmbeddedElevationProfile(
                    key: const ValueKey(
                      'embedded_elevation_profile_sincro_real_pura',
                    ),
                    isCollapsed: _isChartCollapsed,
                    onToggle: () {
                      final bool nextCollapsedState = !_isChartCollapsed;
                      setState(() {
                        _isChartCollapsed = nextCollapsedState;

                        // Mantinguem la neteja de les teves variables primitives si en fas ús de fons
                        selectedIndexGraph = null;
                        selectedIndexStart = null;
                        selectedIndexEnd = null;
                      });

                      // 🧹 Si l'usuari tanca la persiana del perfil, buidem Riverpod globalment
                      if (nextCollapsedState) {
                        ref
                            .read(elevationSelectionProvider.notifier)
                            .clearSelection();
                      }

                      if (nextCollapsedState &&
                          mapController != null &&
                          styleInitialized) {
                        try {
                          // Esborrem completament les geometries del mapa (cercles)
                          setChartInteractionGeometry(mapController!);
                        } catch (e) {
                          debugPrint(
                            "⚠️ Error al netejar geometries en minimitzar: $e",
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🏁 EXECUTOR RECEPTOR DE LA MÀQUINA D'ESTATS SEQÜENCIAL DE SENDA
  void _handleSendaNavigationAction(String? action) {
    if (action == null) return;

    switch (action) {
      case "follow":
        ref
            .read(navigationProvider.notifier)
            .startFollowing(context, mapController);
        break;

      case "clear_imported":
        // 🚀 AFEGIT: Netegem també el panell d'elevacions de fons si l'usuari descarta el track importat
        ref.read(elevationSelectionProvider.notifier).clearSelection();
        ref.read(importedTrackProvider.notifier).clear();
        ref.read(importedWaypointsProvider.notifier).clear();
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
        break;
    }
  }
}
