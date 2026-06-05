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
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/map_bearing_provider.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/providers/barometer_provider.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/screens/stats/stats_screen.dart';
import 'package:senda/services/altitude_logger.dart';
import 'package:senda/services/gpx_exporter.dart';
import 'package:senda/services/gpx_import_flow.dart';
import 'package:senda/services/hgt_service.dart';
import 'package:senda/services/location_permission_flow.dart';
import 'package:senda/services/native_barometer_channel.dart';
import 'package:senda/services/permissions_service.dart';
import 'package:senda/services/recording_handler.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/utils/color_extensions.dart';
import 'package:senda/utils/distance_utils.dart';
import 'package:senda/utils/map_animator.dart';
import 'package:senda/utils/map_layers.dart';
import 'package:senda/widgets/compass_widget.dart';
import 'package:senda/widgets/range_info_panel.dart';
import 'package:senda/widgets/embedded_elevation_profile.dart';
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
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? selectedIndexGraph;
  bool _isChartCollapsed = false;
  DateTime _lastMapUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _mapThrottleMs = 32;
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
      ref.read(trackRecordingProvider.notifier).reset();
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
    final suggestedName = "Punt ${waypoints.length + 1}";
    final name = await AppMessages.showAddWaypointDialog(
      context,
      suggestedName: suggestedName,
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

  void _onFeatureTapped(
    Point<double> point,
    LatLng latLng,
    String featureId,
    String layerId,
    Annotation? annotation,
  ) async {
    // 🛡️ RESTAURACIÓ ORIGINAL: Utilitzem el featureId tal com ho feia el teu codi natiu
    final String wpId = featureId;

    final recorded = ref.read(waypointsProvider);
    final imported = ref.read(importedWaypointsProvider);

    final waypoint = [...recorded, ...imported].firstWhere(
      (w) =>
          w.id == wpId ||
          (w.lat == latLng.latitude && w.lon == latLng.longitude),
      orElse: () => throw Exception("Waypoint no trobat"),
    );

    if (selectedIndexStart != null && selectedIndexEnd != null) {
      final int wpTrackIndex = waypoint.trackIndex;

      final int distToStart = (selectedIndexStart! - wpTrackIndex).abs();
      final int distToEnd = (selectedIndexEnd! - wpTrackIndex).abs();

      setState(() {
        if (distToStart < distToEnd) {
          selectedIndexStart = wpTrackIndex;
        } else {
          selectedIndexEnd = wpTrackIndex;
        }
        selectedIndexGraph = null;
      });

      final startCoords = _getCoordsFromGlobalIndex(selectedIndexStart!);
      final endCoords = _getCoordsFromGlobalIndex(selectedIndexEnd!);
      setChartInteractionGeometry(
        mapController!,
        rangeStartCoords: startCoords,
        rangeEndCoords: endCoords,
      );

      return;
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

  // ─────────────────────────────────────────────────────────────
  // 🔴 REINCORPORACIÓ REALE: EL MÈTODE FALTANT DE GRAVACIÓ INTERNA
  // ─────────────────────────────────────────────────────────────
  void _openRecordingControl(BuildContext context, WidgetRef ref) async {
    final state = ref.read(trackRecordingProvider).recordingState;

    final String? action = await AppMessages.showRecordingControlDialog(
      context: context,
      state: state,
    );

    if (!mounted || action == null) return;

    switch (action) {
      case "start":
        final ok = await requestLocationPermissionsUnified(context, ref);
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

          safeAnimateCamera(CameraUpdate.newLatLngZoom(userGps.position, 18));

          Future.delayed(const Duration(milliseconds: 600), () {
            isProgrammaticMove = false;
          });
        }
        break;

      case "pause":
        RecordingHandler.pause(ref);
        break;

      case "resume":
        RecordingHandler.resume(ref);
        break;

      case "stop":
        _handleStopProcess(context, ref);
        break;
    }
  }

  void _openNavigationControl(
    BuildContext context,
    WidgetRef ref,
    bool hasImportedTrack,
  ) async {
    final navigationState = ref.read(navigationProvider);
    String? action;

    if (!hasImportedTrack) {
      action = "import";
    } else if (hasImportedTrack && !navigationState.isFollowing) {
      action = await AppMessages.showPreNavigationDialog(context);
    } else if (navigationState.isFollowing) {
      action = await AppMessages.showActiveNavigationDialog(
        context: context,
        isFollowPaused: navigationState.isPaused,
      );
    }

    if (!mounted || action == null) return;

    switch (action) {
      case "import":
        setState(() {
          isImportingGpx = true;
          smartCenterEnabled = false;
        });

        final currentPos = await mapController?.cameraPosition;
        if (currentPos != null) {
          mapController?.moveCamera(CameraUpdate.newCameraPosition(currentPos));
        }

        try {
          await pickGpxAndImport(
            context: context,
            ref: ref,
            mapController: mapController,
          );

          final importedData = ref.read(importedTrackProvider);

          if (importedData != null && importedData.points.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 50), () {
              _fitToBounds(importedData.coordinates, instant: true);
            });
          }
        } finally {
          if (mounted) setState(() => isImportingGpx = false);
        }
        break;
      case "follow":
        _onFollowTrack();
        break;

      case "clear_imported":
        final confirm = await AppMessages.showDeleteImportedTrackDialog(
          context,
        );
        if (confirm == true) {
          ref.read(importedTrackProvider.notifier).clear();
          ref.read(importedWaypointsProvider.notifier).clear();
        }
        break;

      case "toggle_pause":
        final currentNavState = ref.read(navigationProvider);
        ref.read(navigationProvider.notifier).state = currentNavState.copyWith(
          isPaused: !currentNavState.isPaused,
        );
        break;

      case "stop_follow":
        final confirm = await AppMessages.showStopFollowingDialog(context);
        if (confirm == true) {
          ref.read(navigationProvider.notifier).stopFollowing();
          ref.read(importedTrackProvider.notifier).clear();
          ref.read(importedWaypointsProvider.notifier).clear();
        }
        break;
    }
  }

  List<double>? _getCoordsFromGlobalIndex(int? index) {
    if (index == null || index < 0) return null;

    final realTrack = ref.read(trackRecordingProvider);
    final importedTrack = ref.read(importedTrackProvider);
    final remainingTrack = ref.read(remainingTrackProvider);

    final int pastCount = realTrack.points.length;

    if (index < pastCount) {
      final pos = realTrack.points[index].position;
      return [pos.longitude, pos.latitude];
    }

    final int futureIndex = index - pastCount;
    final bool showingSimulationFuture =
        ref.read(navigationProvider).isFollowing && remainingTrack != null;

    if (showingSimulationFuture && importedTrack != null) {
      final int realRouteIndex = remainingTrack.anchorIndex + futureIndex;
      if (realRouteIndex < importedTrack.coordinates.length) {
        return importedTrack.coordinates[realRouteIndex];
      }
    } else if (importedTrack != null) {
      if (futureIndex < importedTrack.coordinates.length) {
        return importedTrack.coordinates[futureIndex];
      }
    }
    return null;
  }

  void _handleWaypointClick(dynamic waypoint, int totalPoints) {
    if (waypoint.trackIndex == null || waypoint.trackIndex < 0) return;

    setState(() {
      selectedIndexStart = waypoint.trackIndex;

      final int step = (totalPoints * 0.15).round().clamp(1, totalPoints);
      selectedIndexEnd = (selectedIndexStart! + step).clamp(0, totalPoints - 1);

      selectedIndexGraph = null;
    });

    if (mapController != null && styleInitialized) {
      final startCoords = _getCoordsFromGlobalIndex(selectedIndexStart!);
      final endCoords = _getCoordsFromGlobalIndex(selectedIndexEnd!);

      final bool isCrossed = selectedIndexEnd! < selectedIndexStart!;
      final finalStartCoords = isCrossed ? endCoords : startCoords;
      final finalEndCoords = isCrossed ? startCoords : endCoords;

      try {
        setChartInteractionGeometry(
          mapController!,
          rangeStartCoords: finalStartCoords,
          rangeEndCoords: finalEndCoords,
        );
      } catch (e) {
        debugPrint("⚠️ Error al pintar el tram del waypoint: $e");
      }
    }
  }

  void _handleSendaNavigationAction(String? action) {
    if (action == null) return;

    switch (action) {
      case "follow":
        ref
            .read(navigationProvider.notifier)
            .startFollowing(context, mapController);
        break;

      case "clear_imported":
        ref.read(importedTrackProvider.notifier).clear();
        break;

      case "toggle_pause":
        final currentNavState = ref.read(navigationProvider);
        ref.read(navigationProvider.notifier).state = currentNavState.copyWith(
          isPaused: !currentNavState.isPaused,
        );
        break;

      case "stop_follow":
        ref.read(navigationProvider.notifier).stopFollowing();
        ref.read(importedTrackProvider.notifier).clear();
        break;
    }
  }

  Future<void> _shareTrack() async {
    final recordingTrack = ref.read(trackRecordingProvider);
    if (recordingTrack.points.isEmpty) return;

    final suggested = buildGpxFilename().replaceAll(".gpx", "");
    final name = await AppMessages.askGpxFilename(context, suggested);

    if (name == null || name.isEmpty) return;
    await exportGpx(name, ref, context);

    if (!mounted) return;
    final eliminar = await _askDeleteTrack();

    if (eliminar == true) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("preserve_track_on_start", false);

      ref.read(trackRecordingProvider.notifier).reset();
      ref.read(waypointsProvider.notifier).clear();
      ref.read(timerProvider.notifier).reset();
    } else {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("preserve_track_on_start", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationProvider);
    final trackSettings = ref.watch(trackSettingsProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final hasImportedTrack =
        importedTrack != null && importedTrack.points.isNotEmpty;

    final pressure = ref.watch(barometerProvider).value;

    final isRunning = ref.watch(locationProvider.notifier).isSimulationRunning;
    final isPaused = ref.watch(locationProvider.notifier).isSimulationPaused;
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
                leading: const GpsAccuracyBars(),
                title: const Text("SENDA"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => AltitudeLoggerService().shareLog(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => AltitudeLoggerService().clearLog(),
                  ),
                  if (ref.watch(importedTrackProvider) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
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
                                ? (isPaused ? Colors.blue : Colors.orange)
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
                ],
              ),
        body: Stack(
          children: [
            // 🗺️ 1/4: DIBUIX DE LA CAPA CARTOGRÀFICA DE MAPLIBRE
            RepaintBoundary(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (PointerDownEvent event) {
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
                  },
                  onMapCreated: (controller) {
                    mapController = controller;

                    // 🛡️ SUTURA ORIGINAL COMPATIBLE AL 100%
                    controller.onFeatureTapped.add(_onFeatureTapped);
                  },
                  onStyleLoadedCallback: () async {
                    await setupUserLocationLayer(mapController!);
                    await setupWaypointLayers(mapController!);
                    mapAnimator = MapAnimator(mapController!);
                    waypointLayersReady = true;
                    styleInitialized = true;
                  },
                ),
              ),
            ),
            if (!_fullScreen) ...[
              // 🔋 BARRA D'ESTAT DE GRAVACIÓ SUPERIOR ESQUERRA
              Positioned(
                top: 10,
                left: 10,
                child: RecordingStatusBar(
                  state: ref.watch(
                    trackRecordingProvider.select((t) => t.recordingState),
                  ),
                  duration: ref.watch(timerProvider),
                ),
              ),

              // 🎛️ COLUMNA DE BOTONS FLOTANTS DE LA DRETA (HUD)
              Positioned(
                top: 10,
                right: 12,
                child: Column(
                  children: [
                    // BRÚIXOLA
                    CompassScalePanel(
                      onTapCompass: () {
                        mapController?.animateCamera(CameraUpdate.bearingTo(0));
                      },
                    ),
                    const SizedBox(height: 8),

                    // 🔴 BOTÓ 1: GRAVACIÓ INTERNA (Cercle vermell, Pausa o Play)
                    _buildSquareButton(
                      icon:
                          ref.watch(
                                trackRecordingProvider.select(
                                  (t) => t.recordingState,
                                ),
                              ) ==
                              RecordingState.recording
                          ? Icons.pause_circle_outline
                          : (ref.watch(
                                      trackRecordingProvider.select(
                                        (t) => t.recordingState,
                                      ),
                                    ) ==
                                    RecordingState.paused
                                ? Icons.play_circle_outline
                                : Icons.fiber_manual_record),
                      onTap: () => _openRecordingControl(context, ref),
                    ),
                    const SizedBox(height: 8),
                    // 🗺️ BOTÓ 2: CONTROL GPX SEQÜENCIAL AMB RIVERPOD PUR
                    _buildSquareButton(
                      icon:
                          (ref.watch(importedTrackProvider) == null ||
                              ref
                                  .watch(importedTrackProvider)!
                                  .coordinates
                                  .isEmpty)
                          ? Icons.file_upload_outlined
                          : (ref.watch(
                                  navigationProvider.select(
                                    (n) => n.isFollowing,
                                  ),
                                )
                                ? (ref.watch(
                                        navigationProvider.select(
                                          (n) => n.isPaused,
                                        ),
                                      )
                                      ? Icons.play_arrow_outlined
                                      : Icons.pause)
                                : Icons.navigation_rounded),
                      onTap: () => _openNavigationControl(
                        context,
                        ref,
                        hasImportedTrack,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // BOTÓ DE DADES ESTADÍSTIQUES
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

                    // BOTÓ D'AFEGIR WAYPOINT (Només si es grava)
                    if (ref.watch(trackRecordingProvider).recordingState ==
                        RecordingState.recording) ...[
                      _buildSquareButton(
                        icon: Icons.add_location_alt_outlined,
                        onTap: () => _onAddWaypoint(context, ref),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // BOTÓ DE CENTRAT GPS (SmartCenter)
                    if (!smartCenterEnabled)
                      _buildSquareButton(
                        icon: Icons.gps_fixed,
                        onTap: () {
                          final currentGps = ref.read(locationProvider);
                          setState(() {
                            smartCenterEnabled = true;
                            if (currentGps != null) {
                              _lastCameraCenter = currentGps.position;
                            }
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
              // 📊 PANNELL FLOTANT DE SEGMENT (HUD)
              if (selectedIndexStart != null &&
                  selectedIndexEnd != null &&
                  !_isChartCollapsed)
                Positioned(
                  top: 52,
                  left: 10,
                  child: RangeInfoPanel(
                    selectedIndexStart: selectedIndexStart,
                    selectedIndexEnd: selectedIndexEnd,
                    isChartCollapsed: _isChartCollapsed,
                  ),
                ),

              // 📈 GRÀFIC D'ELEVACIONS EMBEBUT SOTA L'ESCUT DE LA GPU
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
                        if (nextCollapsedState) {
                          selectedIndexGraph = null;
                          selectedIndexStart = null;
                          selectedIndexEnd = null;
                        }
                      });
                      if (nextCollapsedState &&
                          mapController != null &&
                          styleInitialized) {
                        try {
                          setChartInteractionGeometry(mapController!);
                        } catch (e) {
                          debugPrint(
                            "⚠️ Error al netejar geometries en minimitzar: $e",
                          );
                        }
                      }
                    },
                    selectedIndexStart: selectedIndexStart,
                    selectedIndexEnd: selectedIndexEnd,
                    selectedIndexGraph: selectedIndexGraph,
                    onNeedleMove: (idx) {
                      if (selectedIndexGraph == idx) return;
                      setState(() {
                        selectedIndexGraph = idx;
                        selectedIndexStart = null;
                        selectedIndexEnd = null;
                      });
                      final now = DateTime.now();
                      if (now.difference(_lastMapUpdateTime).inMilliseconds >=
                          _mapThrottleMs) {
                        if (mapController != null && styleInitialized) {
                          _lastMapUpdateTime = now;
                          final hoverCoords = _getCoordsFromGlobalIndex(idx);
                          List<double>? routeStartCoords;
                          final currentTrack = ref.read(importedTrackProvider);
                          if (currentTrack != null &&
                              currentTrack.coordinates.isNotEmpty) {
                            routeStartCoords = currentTrack.coordinates.first;
                          }
                          try {
                            setChartInteractionGeometry(
                              mapController!,
                              hoverCoords: hoverCoords,
                              rangeStartCoords: routeStartCoords,
                            );
                          } catch (_) {}
                        }
                      }
                    },
                    onRangeSelected: (start, end) {
                      if (selectedIndexStart == start &&
                          selectedIndexEnd == end) {
                        return;
                      }
                      setState(() {
                        selectedIndexStart = start;
                        selectedIndexEnd = end;
                        selectedIndexGraph = null;
                      });
                      final now = DateTime.now();
                      if (now.difference(_lastMapUpdateTime).inMilliseconds >=
                          _mapThrottleMs) {
                        if (mapController != null && styleInitialized) {
                          _lastMapUpdateTime = now;
                          final coordsA = _getCoordsFromGlobalIndex(start);
                          final coordsB = _getCoordsFromGlobalIndex(end);
                          final bool isCrossed = end < start;
                          final finalStartCoords = isCrossed
                              ? coordsB
                              : coordsA;
                          final finalEndCoords = isCrossed ? coordsA : coordsB;
                          try {
                            setChartInteractionGeometry(
                              mapController!,
                              rangeStartCoords: finalStartCoords,
                              rangeEndCoords: finalEndCoords,
                            );
                          } catch (_) {}
                        }
                      }
                    },
                    onClearSelection: () {
                      if (selectedIndexStart == null &&
                          selectedIndexEnd == null &&
                          selectedIndexGraph == null) {
                        return;
                      }
                      setState(() {
                        selectedIndexStart = null;
                        selectedIndexEnd = null;
                        selectedIndexGraph = null;
                      });
                      if (mapController != null && styleInitialized) {
                        try {
                          setChartInteractionGeometry(mapController!);
                        } catch (_) {}
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
}
