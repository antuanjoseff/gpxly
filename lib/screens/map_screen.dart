import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/map_bearing_provider.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_follow_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/providers/barometer_provider.dart';
import 'package:senda/screens/elevations/elevation_profile_screen.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/screens/stats/stats_screen.dart';
import 'package:senda/services/gpx_exporter.dart';
import 'package:senda/services/gpx_import_flow.dart';
import 'package:senda/services/hgt_service.dart';
import 'package:senda/services/location_permission_flow.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/services/recording_handler.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/ui/bottom_bar/bottom_bar_container.dart';
import 'package:senda/utils/color_extensions.dart';
import 'package:senda/utils/distance_utils.dart';
import 'package:senda/utils/map_animator.dart';
import 'package:senda/utils/map_layers.dart';
import 'package:senda/widgets/compass_widget.dart';
import 'package:senda/widgets/gps_accuracy_bars.dart';
import 'package:senda/widgets/recording_status_bar.dart';
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
  bool hasDoneFirstFixZoom = false;
  bool isProgrammaticMove = false;
  bool isImportingGpx = false;
  bool _isShowingReverseDialog = false;
  bool hasDoneRecoveryFit =
      false; // Flag per controlar que només es recuperi un cop per sessió
  DateTime _lastPrefsSave = DateTime.now();
  LatLng? _lastCameraCenter;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeBarometerChannel.start();
    // Carreguem la posició guardada al disc immediatament.
    _loadLastPosition();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await PermissionsService.ensureBasicLocation(context);
      if (ok) {
        // 2. Engeguem el TEU sistema de GPS (el canal natiu)
        await ref.read(trackProvider.notifier).ensureGpsStarted();

        // 3. Com que el GPS ja està en marxa, esperem que arribi la primera
        // posició del TEU provider per centrar el mapa si encara estem a (0,0).
        final pos = ref.read(trackProvider).currentPosition;
        if (pos != null &&
            (_initialCameraTarget == null ||
                _initialCameraTarget!.latitude == 0)) {
          setState(() {
            _initialCameraTarget = pos;
          });
        }
      }
    });
  }

  void safeMoveCamera(CameraUpdate update) {
    if (isImportingGpx || mapController == null) return;
    mapController!.moveCamera(update);
  }

  void safeAnimateCamera(CameraUpdate update) {
    mapController?.animateCamera(update);
  }

  void _centerOnUser() {
    final pos = ref.read(trackProvider).currentPosition;
    if (pos == null || mapController == null) return;

    safeAnimateCamera(CameraUpdate.newLatLng(pos));
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
    await notifier.startFollowing(context, ref, mapController);
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble("last_lat");
    final lon = prefs.getDouble("last_lon");

    if (mounted) {
      setState(() {
        if (lat != null && lon != null) {
          _initialCameraTarget = LatLng(lat, lon);
          _initialZoom = 14.0; // Un zoom de ciutat estàndard
        } else {
          // Si no hi ha res, una posició per defecte (ex. Catalunya/BCN)
          // per no aparèixer al mig de l'oceà
          _initialCameraTarget = const LatLng(41.3851, 2.1734);
          _initialZoom = 7.0;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Limpieza del observer
    NativeBarometerChannel.stop();
    super.dispose();
  }

  Future<void> _savePositionToPrefs() async {
    final pos = ref.read(trackProvider).currentPosition;
    if (pos != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("last_lat", pos.latitude);
      await prefs.setDouble("last_lon", pos.longitude);
      _lastPrefsSave = DateTime.now(); // Actualitzem la marca de temps
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Aquest mètode es dispara sol quan l'usuari torna de "Ajustos"
    if (state == AppLifecycleState.resumed) {
      // 1. Actualitzem l'estat dels permisos al provider
      final notifier = ref.read(permissionsProvider.notifier);
      await notifier.checkServiceStatus();
      await notifier.checkPermissions();

      // 2. Mirem si teníem l'acció pendent
      final permState = ref.read(permissionsProvider);

      if (permState.serviceEnabled) {
        if (permState.shouldResumeRecording) {
          notifier.consumeSignal();
          RecordingHandler.start(context, ref);
        } else if (permState.shouldResumeFollowing) {
          notifier.consumeFollowSignal();
          _onFollowTrack();
        }
      }
    }
  }

  void _handleStopProcess(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();

    final result = await AppMessages.showStopRecordingDialog(context);
    if (!mounted) return;
    if (result == null) return;

    // 1. Obtenim la durada actual del cronòmetre independent
    final finalDuration = ref.read(timerProvider);

    // 2. Aturem el cronòmetre (deixa de comptar)
    ref.read(timerProvider.notifier).pause();

    // 3. Passem la durada al track perquè la guardi en el seu estat final
    await ref.read(trackProvider.notifier).stopRecording(finalDuration);
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.iconBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(
          icon,
          color: AppColors.iconForegroundColor,
          size: 26, // 🎯 Una mica més petita per la nova mida de 52px
        ),
      ),
    );
  }

  void _onAddWaypoint(BuildContext context, WidgetRef ref) async {
    final track = ref.read(trackProvider);
    if (track.coordinates.isEmpty) return;

    final lastCoords = track.coordinates.last; // [lon, lat]
    final lastAlt = track.altitudes.isNotEmpty ? track.altitudes.last : 0.0;

    // 1. OBTENIR ALÇADA REAL (HGT)
    // 🔥 CORRECCIÓ: Ara rebem (altitud, status). Ens quedem només amb l'altitud.
    final (correctedAlt, _) = await HgtService().getCorrectedElevation(
      lastCoords[1], // lat
      lastCoords[0], // lon
      lastAlt,
    );

    // 2. DIÀLEG DE NOM
    final waypoints = ref.read(waypointsProvider);
    final suggestedName = "Punt ${waypoints.length + 1}";
    final name = await AppMessages.showAddWaypointDialog(
      context,
      suggestedName: suggestedName,
    );

    if (name == null || name.isEmpty) return;

    // 3. CREAR WAYPOINT AMB DADES CORREGIDES
    final wp = Waypoint(
      id: "rec_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      lat: lastCoords[1],
      lon: lastCoords[0],
      trackIndex: track.coordinates.length - 1,
      ele: correctedAlt, // ✅ Ja és el double corregit
      distanceAtPoint: track.distance,
      time: DateTime.now(),
    );

    ref.read(waypointsProvider.notifier).add(wp);
  }

  void _fitToBounds(List<List<double>> coords, {bool instant = false}) {
    if (coords.isEmpty || mapController == null) return;

    final lats = coords.map((c) => c[1]).toList();
    final lons = coords.map((c) => c[0]).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lons.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lons.reduce((a, b) => a > b ? a : b),
      ),
    );

    if (instant) {
      mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 50,
          right: 50,
          top: 50,
          bottom: 50,
        ),
      );
    } else {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 50,
          right: 50,
          top: 50,
          bottom: 50,
        ),
      );
    }
  }

  // Importa Point de dart:math si no el tens
  void _onFeatureTapped(
    Point<double> point,
    LatLng latLng,
    String featureId,
    String layerId,
    Annotation? annotation,
  ) async {
    // 1. Busquem quina "feature" s'ha clicat a les capes de waypoints
    final features = await mapController?.queryRenderedFeatures(point, [
      'waypoints_recorded_layer',
      'waypoints_imported_layer',
    ], null);

    if (features == null || features.isEmpty) return;

    // 2. Extraiem el waypoint_id de les propietats del GeoJSON
    final dynamic feature = features.first;
    final String? wpId = feature['properties']?['waypoint_id'];

    if (wpId == null) return;

    // 3. Busquem el waypoint en els nostres providers
    final recorded = ref.read(waypointsProvider);
    final imported = ref.read(importedWaypointsProvider);
    final waypoint = [...recorded, ...imported].firstWhere(
      (w) => w.id == wpId,
      orElse: () => throw Exception("Waypoint no trobat"),
    );

    // 4. Calculem el temps transcorregut
    Duration? elapsed;

    // Decidim de quin track agafem l'hora d'inici
    final track = wpId.startsWith('rec_')
        ? ref.read(trackProvider)
        : ref.read(importedTrackProvider);

    if (track != null && track.timestamps.isNotEmpty && waypoint.time != null) {
      // Diferència entre l'hora del waypoint i l'hora del primer punt del track
      elapsed = waypoint.time!.difference(track.timestamps.first);
    }

    // 5. Obrim el diàleg amb tota la informació
    if (mounted) {
      AppMessages.showWaypointDetails(context, waypoint, elapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(
      trackProvider.select((t) => t.recordingState),
    );

    // 2. La resta de providers es mantenen igual perquè no canvien cada segon
    final trackSettings = ref.watch(trackSettingsProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final hasImportedTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;
    final trackFollowState = ref.watch(trackFollowNotifierProvider);

    final pressure = ref.watch(barometerProvider).value;
    final isRunning = ref.watch(trackProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(trackProvider.notifier).isSimulationPaused;

    ref.listen(trackProvider, (prev, next) async {
      if (!styleInitialized || mapController == null) return;

      // ───────────────────────────────────────────────
      // 0) ACTUALITZACIÓ VISUAL I GUARDAT PERIÒDIC
      // ───────────────────────────────────────────────
      if (next.currentPosition != null) {
        // Punt blau sempre fluid
        mapAnimator.updateUserPositionDirect(next.currentPosition!);

        // --- GUARDAT EFICIENT (Cada 5 minuts) ---
        final ara = DateTime.now();
        if (ara.difference(_lastPrefsSave).inMinutes >= 5) {
          _savePositionToPrefs(); // Crida a la funció que hem creat abans
        }
      }

      mapAnimator.updateFromTrack(next);

      // Si estem important un GPX, aturem qualsevol lògica que mogui la càmera.
      if (isImportingGpx) {
        return;
      }

      // ───────────────────────────────────────────────
      // 3) PRIMER FIX GPS (Només si el mapa està "buit")
      // ───────────────────────────────────────────────
      if (next.currentPosition != null &&
          prev?.currentPosition == null &&
          next.coordinates.isEmpty) {
        hasDoneFirstFixZoom = true;
        final pos = next.currentPosition!;
        isProgrammaticMove = true;

        _lastCameraCenter = pos;
        safeAnimateCamera(CameraUpdate.newLatLngZoom(pos, 18));

        Future.delayed(const Duration(milliseconds: 300), () {
          isProgrammaticMove = false;
        });
        return;
      }

      // ───────────────────────────────────────────────
      // 4) FIT TO BOUNDS (Només Recuperació Inicial)
      // ───────────────────────────────────────────────
      final isRecoveringTrack =
          (prev?.coordinates.isEmpty ?? true) &&
          next.coordinates.length > 1 &&
          !hasDoneRecoveryFit;

      if (isRecoveringTrack) {
        hasDoneRecoveryFit = true;
        _fitToBounds(next.coordinates, instant: true);
        return;
      }

      // ───────────────────────────────────────────────
      // 5) SmartCenter (Seguiment actiu)
      // ───────────────────────────────────────────────
      if (smartCenterEnabled &&
          next.currentPosition != null &&
          !isProgrammaticMove) {
        double distanceSinceLastMove = 999.0;

        if (_lastCameraCenter != null) {
          distanceSinceLastMove = calculateDistanceManual(
            _lastCameraCenter!.latitude,
            _lastCameraCenter!.longitude,
            next.currentPosition!.latitude,
            next.currentPosition!.longitude,
          );
        }

        // Si l'usuari s'ha allunyat més de 3 metres del CENTRE actual de la càmera...
        if (distanceSinceLastMove > 3.0) {
          isProgrammaticMove = true;
          _lastCameraCenter =
              next.currentPosition; // 🎯 Actualitzem la referència!

          safeAnimateCamera(CameraUpdate.newLatLng(next.currentPosition!));

          Future.delayed(const Duration(milliseconds: 600), () {
            isProgrammaticMove = false;
          });
        }
      }
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

      if (isImportingGpx) {
        _fitToBounds(next.coordinates);
      }
    });

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
      if (next.showReverseTrackDialog && !_isShowingReverseDialog) {
        _isShowingReverseDialog = true; // Bloqueamos nuevas aperturas

        final accept = await AppMessages.showReverseTrackDialog(context);

        if (accept == true) {
          ref.read(trackFollowNotifierProvider.notifier).reverseImportedTrack();
        } else {
          ref
              .read(trackFollowNotifierProvider.notifier)
              .dismissReverseTrackDialog();
        }

        _isShowingReverseDialog = false; // Liberamos cuando el usuario cierra
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

    // 🔔 ICONA D’ALARMES ACTIVES
    final alarms = ref.watch(alarmSettingsProvider);

    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

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
                  'Senda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),

                actions: [
                  // Dins de l'actions de l'AppBar:
                  if (ref.watch(importedTrackProvider) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          final notifier = ref.read(trackProvider.notifier);
                          if (!isRunning) {
                            notifier.simulateImportedTrack();
                          } else {
                            notifier.toggleSimulationPause();
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isRunning
                                ? (isPaused
                                      ? Colors.blue
                                      : Colors
                                            .orange) // Blau si pausa, taronja si corre
                                : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !isRunning
                                ? Icons.play_arrow
                                : (isPaused ? Icons.play_arrow : Icons.pause),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  if (pressure != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        "${pressure.toStringAsFixed(1)} hPa",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                  if (anyAlarmActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlarmSettingsTab(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white, // Cercle blanc
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.red, // Icona vermella
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Botó de settings
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white, // Cercle blanc
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.primary, // Skyblue
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const GpsAccuracyBars(),

                  const SizedBox(width: 8),
                ],
              ),

        body: Stack(
          children: [
            RepaintBoundary(
              child: Listener(
                behavior: HitTestBehavior.translucent,

                onPointerDown: (PointerDownEvent event) {
                  if (smartCenterEnabled) {
                    setState(() => smartCenterEnabled = false);
                  }
                },
                child: MapLibreMap(
                  tiltGesturesEnabled: false,
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
                    // 1. Si el moviment és de l'app (SmartCenter/Programat), sortim immediatament
                    if (isProgrammaticMove) return;

                    final pos = mapController
                        ?.cameraPosition; // MapLibre ja el té, no cal 'await' normalment
                    if (pos == null) return;
                    ref.read(mapBearingProvider.notifier).update(pos.bearing);
                    // 2. FILTRE DE ZOOM: Només actualitzem si el canvi és notable (> 0.2)
                    // Això evita que el build es dispari per micro-ajustaments
                    final currentZoom = ref.read(mapZoomProvider);
                    if ((currentZoom - pos.zoom).abs() > 0.2) {
                      ref.read(mapZoomProvider.notifier).update(pos.zoom);
                    }

                    // 4. GUARDAT A PREFS: Aquest és el millor lloc per fer el guardat de seguretat
                    // perquè el mapa està quiet i no bloquegem frames de moviment.
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble("last_lat", pos.target.latitude);
                    await prefs.setDouble("last_lon", pos.target.longitude);
                    await prefs.setDouble("last_zoom", pos.zoom);
                  },

                  onMapCreated: (controller) {
                    mapController = controller;
                    controller.onFeatureTapped.add(_onFeatureTapped);
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
                  state: recordingState,
                  duration: ref.watch(timerProvider),
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
                    CompassScalePanel(
                      onTapCompass: () {
                        mapController?.animateCamera(CameraUpdate.bearingTo(0));
                      },
                    ),

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
                        state: recordingState,

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
                            safeAnimateCamera(
                              CameraUpdate.newLatLngZoom(pos, 18),
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
                        onImportTrack: () async {
                          // 1. BLOQUEIG ATÒMIC (Immediat)
                          setState(() {
                            isImportingGpx = true;
                            smartCenterEnabled = false;
                          });

                          // 2. NETEJA DE CÀMERA
                          // Com que no hi ha stopAnimation, movem la càmera on ja està
                          // però amb moveCamera per tallar qualsevol animació en curs.
                          final currentPos =
                              await mapController?.cameraPosition;
                          if (currentPos != null) {
                            mapController?.moveCamera(
                              CameraUpdate.newCameraPosition(currentPos),
                            );
                          }

                          try {
                            await pickGpxAndImport(
                              context: context,
                              ref: ref,
                              mapController: mapController,
                            );

                            // 3. El FitToBounds del track importat
                            final importedCoords = ref
                                .read(importedTrackProvider)
                                ?.coordinates;
                            if (importedCoords != null &&
                                importedCoords.isNotEmpty) {
                              // Fem el fitToBounds amb un micro-delay perquè el mapa hagi digerit el GPX
                              Future.delayed(
                                const Duration(milliseconds: 50),
                                () {
                                  _fitToBounds(importedCoords, instant: true);
                                },
                              );
                            }

                            await Future.delayed(const Duration(seconds: 2));
                          } finally {
                            if (mounted) setState(() => isImportingGpx = false);
                          }
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
      ref.read(timerProvider.notifier).reset();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }
}
