// lib/screens/map/map_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/navigation_state.dart'; // Afegit per a la nova lògica de navegació
import 'package:senda/models/track.dart'; // Afegit per l'enum RecordingState si s'usa a la UI
import 'package:senda/models/user_position.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
// ✅ ADAPTAT: Importem la nova xarxa de providers modulars
import 'package:senda/notifiers/location_notifier.dart'; // Bloc 1: Hardware i GPS
import 'package:senda/notifiers/map_bearing_provider.dart';
import 'package:senda/notifiers/navigation_notifier.dart'; // Bloc 3: Autòmat de Navegació
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart'; // Bloc 2: Gravador i TrackStats
import 'package:senda/notifiers/timer_notifier.dart';
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

import '../notifiers/gps_speed_notifier.dart';

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
  bool hasDoneRecoveryFit = false; // Control de recuperació per sessió
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
    _loadLastPosition();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await PermissionsService.ensureBasicLocation(context);
      if (ok) {
        // ✅ ADAPTAT: Engeguem el sensor GPS a través del nou locationProvider
        await ref.read(locationProvider.notifier).ensureGpsStarted();

        // ✅ ADAPTAT: Llegim la posició actual des del nou model UserPosition
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

  void safeMoveCamera(CameraUpdate update) {
    if (isImportingGpx || mapController == null) return;
    mapController!.moveCamera(update);
  }

  void safeAnimateCamera(CameraUpdate update) {
    mapController?.animateCamera(update);
  }

  void _centerOnUser() {
    // ✅ ADAPTAT: Llegim la posició actual directament del locationProvider (Punt Blau)
    final userGps = ref.read(locationProvider);
    if (userGps == null || mapController == null) return;

    safeAnimateCamera(CameraUpdate.newLatLng(userGps.position));
  }

  Future<void> _onFollowTrack() async {
    // ✅ ADAPTAT: Utilitzem el nou proveïdor analític de navegació Senda
    final notifier = ref.read(navigationProvider.notifier);
    final state = ref.read(navigationProvider);

    if (state.isFollowing) {
      notifier.stopFollowing();
      return;
    }

    // El nou notifier ja s'encarrega de demanar permisos, engegar GPS i fer el primer enquadrament neta
    await notifier.startFollowing(context, mapController);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NativeBarometerChannel.stop();
    super.dispose();
  }

  Future<void> _savePositionToPrefs() async {
    // ✅ ADAPTAT: Desar a disc la darrera posició llegida des del locationProvider
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

  void _handleStopProcess(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();

    final result = await AppMessages.showStopRecordingDialog(context);
    if (!mounted) return;
    if (result == null) return;

    final finalDuration = ref.read(timerProvider);
    ref.read(timerProvider.notifier).pause();

    // ✅ ADAPTAT: Aturem la gravació utilitzant el nou trackRecordingProvider
    await ref
        .read(trackRecordingProvider.notifier)
        .stopRecording(finalDuration);
    if (!context.mounted) return;

    if (result == "share") {
      await _shareTrack();
      return;
    }

    final eliminar = await _askDeleteTrack();
    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);
      ref.read(trackRecordingProvider.notifier).reset(); // ✅ ADAPTAT
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
        child: Icon(icon, color: AppColors.iconForegroundColor, size: 26),
      ),
    );
  }

  void _onAddWaypoint(BuildContext context, WidgetRef ref) async {
    // ✅ ADAPTAT: Llegim de forma unificada des del nou trackRecordingProvider
    final recordingTrack = ref.read(trackRecordingProvider);
    if (recordingTrack.points.isEmpty) return;

    // Llegim l'últim punt gravat utilitzant el nou model UserPosition
    final lastPoint = recordingTrack.points.last;
    final lastLat = lastPoint.position.latitude;
    final lastLon = lastPoint.position.longitude;
    final lastAlt = lastPoint.altitude;

    // 1. OBTENIR ALÇADA REAL CORREGIDA
    final (correctedAlt, _) = await HgtService().getCorrectedElevation(
      lastLat,
      lastLon,
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

    // 3. CREAR WAYPOINT AMB LES NOVES REFERÈNCIES ATÒMIQUES
    final wp = Waypoint(
      id: "rec_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      lat: lastLat,
      lon: lastLon,
      trackIndex:
          recordingTrack.points.length -
          1, // Basat en la llista compacta de punts
      ele: correctedAlt,
      distanceAtPoint: recordingTrack.distance,
      time: DateTime.now(),
    );

    ref.read(waypointsProvider.notifier).add(wp);
  }

  void _fitToBounds(List<List<double>> coords, {bool instant = false}) {
    if (coords.isEmpty || mapController == null) return;

    // ✅ CORREGIDO: Añadimos [1] para la Latitud y [0] para la Longitud
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
    final waypoint = [...recorded, ...imported].firstWhere(
      (w) => w.id == wpId,
      orElse: () => throw Exception("Waypoint no trobat"),
    );

    Duration? elapsed;

    // ✅ ADAPTAT: Llegim de forma compatible usant el nou trackRecordingProvider
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
    // ✅ ADAPTAT: Connectem les variables reactives visuals amb els proveïdors optimitzats
    final navigationState = ref.watch(
      navigationProvider,
    ); // Substitueix trackFollowNotifierProvider
    final trackSettings = ref.watch(trackSettingsProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final hasImportedTrack =
        importedTrack != null && importedTrack.points.isNotEmpty;

    final pressure = ref.watch(barometerProvider).value;

    // ✅ ADAPTAT: Llegim els indicadors d'estat a través del nou locationProvider i del gravador
    final isRunning = ref.watch(locationProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(locationProvider.notifier).isSimulationPaused;

    // ─────────────────────────────────────────────────────────────
    // 🛰️ OIENT A: MOVIMENT DEL PUNT BLAU I CONTROL DE CÀMERA (GPS)
    // ─────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────
    // 🛰️ OIENT A: MOVIMENT DEL PUNT BLAU I CONTROL DE CÀMERA (GPS)
    // ─────────────────────────────────────────────────────────────
    ref.listen<UserPosition?>(locationProvider, (prev, next) async {
      if (!styleInitialized || mapController == null || next == null) return;

      // 🔄 MODIFICAT: En lloc d'un salt directe, deleguem la posició al motor d'animació fluida
      mapAnimator.animateUserPosition(next.position); // 👈 CANVIAT AQUÍ!

      // --- GUARDAT EFICIENT EN MEMÒRIA CACHÉ (Cada 5 minuts) ---
      final ara = DateTime.now();
      if (ara.difference(_lastPrefsSave).inMinutes >= 5) {
        _savePositionToPrefs();
      }

      if (isImportingGpx) return;

      // 2. PRIMER FIX GPS (Només si la llista del gravador està totalment buida)
      final recordingPoints = ref.read(trackRecordingProvider).points;
      if (prev == null && recordingPoints.isEmpty) {
        hasDoneFirstFixZoom = true;
        isProgrammaticMove = true;

        _lastCameraCenter = next.position;
        safeAnimateCamera(CameraUpdate.newLatLngZoom(next.position, 18));

        Future.delayed(const Duration(milliseconds: 300), () {
          isProgrammaticMove = false;
        });
        return;
      }

      // 3. SmartCenter (Seguiment automàtic actiu de la càmera)
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
          isProgrammaticMove = true;
          _lastCameraCenter = next.position;

          // 🔄 ADAPTACIÓ FLUIDA: Perquè la pròpia càmera acompanyi el desplaçament fluid
          // de l'animador del punt blau en lloc de fer un salt ràpid, usem animateCamera.
          safeAnimateCamera(CameraUpdate.newLatLng(next.position));

          Future.delayed(const Duration(milliseconds: 600), () {
            isProgrammaticMove = false;
          });
        }
      }
    });

    // ─────────────────────────────────────────────────────────────
    // 📊 OIENT B: GRAVACIÓ FÍSICA (LÍNIA I TRAMS ANIMATS)
    // ─────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────
    // 📊 OIENT B: GRAVACIÓ FÍSICA (LÍNIA I TRAMS ANIMATS)
    // ─────────────────────────────────────────────────────────────
    ref.listen<Track>(trackRecordingProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

      // ✅ ADAPTAT: Eliminem 'navigationState' perquè la teva funció real només rep el track!
      mapAnimator.updateFromTrack(next);

      if (isImportingGpx) return;

      // RECUPERACIÓ INICIAL DE TRAÇAT DES DE CACHÉ (Fit Bounds un sol cop)
      final bool isRecoveringTrack =
          (prev == null || prev.points.isEmpty) &&
          next.points.length > 1 &&
          !hasDoneRecoveryFit;

      if (isRecoveringTrack) {
        hasDoneRecoveryFit = true;

        final List<List<double>> mapCoords = next.coordinates;
        _fitToBounds(mapCoords, instant: true);
      }
    });

    // ─────────────────────────────────────────────────────────────
    // 🗺️ OIENT C: SET DE CAPES DEL TRACK IMPORTAT (GPX)
    // ─────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────
    // 🗺️ OIENT C: SET DE CAPES DEL TRACK IMPORTAT (GPX PROGRESSIU)
    // ─────────────────────────────────────────────────────────────
    ref.listen<Track?>(importedTrackProvider, (prev, next) {
      if (!styleInitialized || mapController == null) return;

      // ✅ CANVI CLAU: En lloc de llegir 'next.coordinates' (que és el bloc sencer),
      // demanem el segment tallat que s'ha estès en aquest mil·lisegon de simulació.
      final List<List<double>> coordsVisibles = ref
          .read(importedTrackProvider.notifier)
          .visibleCoordinates;

      if (next == null || coordsVisibles.isEmpty) {
        mapController!.setGeoJsonSource("imported_track", {
          "type": "FeatureCollection",
          "features": [],
        });
        return;
      }

      // Pintem al GeoJSON de MapLibre només la llista dinàmica progressiva
      mapController!.setGeoJsonSource("imported_track", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": coordsVisibles,
            }, // 👈 MODIFICAT AQUÍ!
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

      // El FitToBounds general només el fem un cop en carregar el fitxer original
      if (isImportingGpx && next.coordinates.isNotEmpty) {
        _fitToBounds(next.coordinates);
      }
    });

    // ─────────────────────────────────────────────────────────────
    // 📍 RECEPTORS DE REFRESC DE LES CAPES DE WAYPOINTS
    // ─────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────
    // 🎨 RECEPTORS DE CANVIS EN ELS ESTILS VISUALS DE CAPA
    // ─────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────
    // 🔔 OIENT D: GESTIÓ D'ALERTES I DIÀLEGS EN PANTALLA (Navegació Senda)
    // ─────────────────────────────────────────────────────────────
    // ✅ ADAPTAT: Substituïm la subscripció del vell trackFollowNotifierProvider pel navigationProvider
    ref.listen<NavigationState>(navigationProvider, (prev, next) {
      if (next.showBackOnTrackSnackbar == true) {
        AppMessages.showBackOnTrackPersistentSnackbar(context, ref);
        ref.read(navigationProvider.notifier).dismissBackOnTrackAlert();
      }
    });

    ref.listen<NavigationState>(navigationProvider, (prev, next) async {
      if (next.showReverseTrackDialog && !_isShowingReverseDialog) {
        _isShowingReverseDialog = true; // Bloqueig de doble finestra

        ref.read(navigationProvider.notifier).sounds.playReversedTrackSound();

        final accept = await AppMessages.showReverseTrackDialog(context);

        if (accept == true) {
          ref.read(navigationProvider.notifier).reverseImportedTrack();
        } else {
          ref.read(navigationProvider.notifier).dismissReverseTrackDialog();
        }

        _isShowingReverseDialog = false; // Alliberem el control al tancar
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

    // ─────────────────────────────────────────────────────────────
    // 📐 PREPARACIÓ DELS VISORS GENERALS DE L'APPBAR
    // ─────────────────────────────────────────────────────────────
    if (_initialCameraTarget == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                title: Text("SENDA"),
                actions: [
                  // ✅ ADAPTAT: Comprovem si hi ha un track importat a través de la nova referència
                  if (ref.watch(importedTrackProvider) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // ✅ ADAPTAT: El simulador de traçats ara està delegat de forma neta al locationProvider
                          final notifier = ref.read(locationProvider.notifier);
                          if (!isRunning) {
                            final importedData = ref.read(
                              importedTrackProvider,
                            );
                            notifier.simulateImportedTrack(importedData);
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.red,
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.primary,
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
                  // 🔥 BLINDATGE CRÍTIC: Si l'aplicació està movent el mapa per codi (SmartCenter actiu),
                  // ignorem completament el toc perquè no desconnecti el seguiment en temps real.
                  if (isProgrammaticMove) return;

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
                    if (isProgrammaticMove) return;

                    final pos = mapController?.cameraPosition;
                    if (pos == null) return;

                    ref.read(mapBearingProvider.notifier).update(pos.bearing);

                    final currentZoom = ref.read(mapZoomProvider);
                    if ((currentZoom - pos.zoom).abs() > 0.2) {
                      ref.read(mapZoomProvider.notifier).update(pos.zoom);
                    }

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
              // -------------------------
              // PÍNDOLA FLOTANT (CENTRAT DALT)
              // -------------------------
              Positioned(
                top: 10,
                left: 10,
                child: RecordingStatusBar(
                  // ✅ ADAPTAT: Passem el RecordingState real des del nou gravador inalterable
                  state: ref.watch(
                    trackRecordingProvider.select((t) => t.recordingState),
                  ),
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
                    // ✅ ADAPTAT: Llegim l'estat de gravació des del nou trackRecordingProvider
                    if (ref.watch(trackRecordingProvider).recordingState ==
                        RecordingState.recording) ...[
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
                          // ✅ ADAPTAT: Afegim les línies de control temporal de moviment programat
                          final currentGps = ref.read(locationProvider);
                          setState(() {
                            smartCenterEnabled = true;
                            if (currentGps != null)
                              _lastCameraCenter = currentGps.position;
                            isProgrammaticMove = true;
                          });

                          _centerOnUser();

                          Future.delayed(const Duration(milliseconds: 600), () {
                            isProgrammaticMove = false;
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

                        // ✅ ADAPTAT: Passem el RecordingState real mitjançant el paràmetre requerit
                        state: ref.watch(
                          trackRecordingProvider.select(
                            (t) => t.recordingState,
                          ),
                        ),

                        onStart: () async {
                          final ok = await requestLocationPermissionsUnified(
                            context,
                            ref,
                          );
                          if (!ok) return;

                          await RecordingHandler.start(context, ref);

                          final map = mapController;
                          final userGps = ref.read(locationProvider);

                          if (map != null && userGps != null) {
                            setState(() {
                              smartCenterEnabled = true;
                              _lastCameraCenter = userGps.position;
                              isProgrammaticMove = true;
                            });

                            safeAnimateCamera(
                              CameraUpdate.newLatLngZoom(userGps.position, 18),
                            );

                            Future.delayed(
                              const Duration(milliseconds: 600),
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
                        onImportTrack: () async {
                          setState(() {
                            isImportingGpx = true;
                            smartCenterEnabled = false;
                          });

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

                            final importedData = ref.read(
                              importedTrackProvider,
                            );

                            if (importedData != null &&
                                importedData.points.isNotEmpty) {
                              Future.delayed(
                                const Duration(milliseconds: 50),
                                () {
                                  _fitToBounds(
                                    importedData.coordinates,
                                    instant: true,
                                  );
                                },
                              );
                            }

                            await Future.delayed(const Duration(seconds: 2));
                          } finally {
                            if (mounted) setState(() => isImportingGpx = false);
                          }
                        },

                        onFollowTrack: () {
                          if (navigationState.isFollowing) {
                            ref
                                .read(navigationProvider.notifier)
                                .stopFollowing();
                            ref.read(importedTrackProvider.notifier).clear();
                          } else {
                            _onFollowTrack();
                          }
                        },

                        // ✅ AFEGIT: Mantenim el flag de control requerit pel teu contenidor
                        isFollowingTrack: navigationState.isFollowing,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareTrack() async {
    // ✅ ADAPTAT: Llegim del nou trackRecordingProvider unificat
    final recordingTrack = ref.read(trackRecordingProvider);
    if (recordingTrack.points.isEmpty) return;

    // 1. Proposar nom editable
    final suggested = buildGpxFilename().replaceAll(".gpx", "");
    final name = await AppMessages.askGpxFilename(context, suggested);

    if (name == null || name.isEmpty) return;

    // 2. Exportar i compartir l'arxiu de punts únics
    await exportGpx(name, ref, context);

    if (!mounted) return;

    // 3. Preguntar si vol eliminar o mantenir el track gravat
    final prefs = await SharedPreferences.getInstance();
    final eliminar = await _askDeleteTrack();

    if (eliminar == true) {
      prefs.setBool("preserve_track_on_start", false);

      // ✅ ADAPTAT: Reset complet net a través del nou gravador inalterable
      ref.read(trackRecordingProvider.notifier).reset();

      ref.read(waypointsProvider.notifier).clear();
      ref.read(timerProvider.notifier).reset();
    } else {
      prefs.setBool("preserve_track_on_start", true);
    }
  }
}
