// lib/screens/elevations/elevation_profile_screen.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/imported_track_settings_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/remaining_track_notifier.dart';
import 'package:strack_rec/notifiers/track_settings_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_recorded_notifier.dart';
import 'package:strack_rec/screens/elevations/widgets/elevation_chart_widget.dart';
import 'package:strack_rec/screens/elevations/widgets/header_legend_widget.dart';
import 'package:strack_rec/screens/elevations/widgets/waypoints_list_widget.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/theme/app_dimensions.dart';
import 'package:strack_rec/utils/distance_utils.dart';

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndexGraph;
  int? _prevWpIndex;
  int? _lastWpIndex;

  // 🟢 FUNCIÓ DE SELECCIÓ CORREGIDA: Comunica l'estat directament al provider global
  void _onToggleWaypoint(Waypoint wp, Set<int> allWpIndexes) {
    setState(() {
      selectedIndexGraph = null; // Neteja la línia flotant
    });
    ref
        .read(elevationSelectionProvider.notifier)
        .setPointFromMapSelectionTool(wp.trackIndex);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final recordingState = ref.watch(trackRecordingProvider).recordingState;
    // 🚨 LLEGIM EL PROVIDER DE SELECCIÓ COMPARTIT COM A VARIABLES FINALS DE REDIBUIX
    final selection = ref.watch(elevationSelectionProvider);
    final int? selectedIndexStart = selection.startTrackIndex;
    final int? selectedIndexEnd = selection.endTrackIndex;

    // Escuchadores de datos de Riverpod
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);
    final follow = ref.watch(navigationProvider);

    final realAlts = real.altitudes;
    final realDists = real.distances;
    final bool isRecording = real.recordingState == RecordingState.recording;
    final importedDists = calculateDistances(imported?.coordinates ?? []);

    final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
    final bool isFollowingOnTrack =
        follow.isFollowing && !follow.isOffTrack && remaining != null;

    // Dades efectives del gràfic segons mode
    // Dades efectives del gràfic segons mode
    late List<double> chartPastAlts;
    late List<double> chartPastDists;
    late List<double> futureAlts;
    late List<double> futureDistsGlobal;

    if (isRecording && isFollowingOnTrack) {
      print("🔍 [MODE PERFIL] Actiu: GRAVAR + SEGUIR (Mixt)");
      chartPastAlts = realAlts;
      chartPastDists = realDists;

      final remainingAlts = remaining.altitudes;
      final remainingDists = remaining.distances;

      double elevationOffset = 0.0;
      if (realAlts.isNotEmpty && remainingAlts.isNotEmpty) {
        elevationOffset = realAlts.last - remainingAlts.first;
      }

      futureAlts = [
        for (int i = 0; i < remainingAlts.length; i++)
          remainingAlts[i] + elevationOffset,
      ];

      futureDistsGlobal = [
        for (int i = 0; i < remainingDists.length; i++)
          pastLastDist + remainingDists[i] + (i == 0 ? 0.001 : 0.0),
      ];
    } else if (isRecording && imported != null) {
      print("🔍 [MODE PERFIL] Actiu: GRAVAR + TRACK IMPORTAT PASSIU");
      chartPastAlts = realAlts;
      chartPastDists = realDists;
      futureAlts = imported.altitudes;
      futureDistsGlobal = importedDists;
    } else if (isRecording) {
      print("🔍 [MODE PERFIL] Actiu: NOMÉS GRAVAR (Sense res més)");
      chartPastAlts = realAlts;
      chartPastDists = realDists;
      futureAlts = const [];
      futureDistsGlobal = const [];
    } else if (follow.isFollowing && imported != null) {
      print("🔍 [MODE PERFIL] Actiu: NOMÉS SEGUIR");
      chartPastAlts = const [];
      chartPastDists = const [];
      futureAlts = imported.altitudes;
      futureDistsGlobal = importedDists;
    } else {
      print(
        "🔍 [MODE PERFIL] Actiu: REPÒS / INICIAL (imported: ${imported != null})",
      );
      chartPastAlts = realAlts;
      chartPastDists = realDists;
      futureAlts = imported?.altitudes ?? [];
      futureDistsGlobal = importedDists;
    }

    final globalDists = <double>[...chartPastDists, ...futureDistsGlobal];
    final globalAlts = <double>[...chartPastAlts, ...futureAlts];

    print(
      "📊 [MÈTODE BUILD] globalDists length: ${globalDists.length}, maxDist detectada: ${globalDists.isNotEmpty ? globalDists.last : 'buida'}",
    );

    // WAYPOINTS
    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedTrackColor = ref.watch(importedTrackSettingsProvider).color;

    final recordedWaypointGlobalDists = recordedWps
        .where((wp) => wp.trackIndex >= 0 && wp.trackIndex < realDists.length)
        .map((wp) => realDists[wp.trackIndex])
        .toList(growable: false);

    final importedWaypointGlobalDists = <double>[];

    if (isRecording && isFollowingOnTrack) {
      for (final wp in importedWps) {
        final idx = wp.trackIndex;
        if (idx < remaining.anchorIndex) continue;

        final futureIdx = idx - remaining.anchorIndex;
        if (futureIdx < remaining.distances.length) {
          importedWaypointGlobalDists.add(
            pastLastDist + remaining.distances[futureIdx],
          );
        }
      }
    } else if (!isRecording) {
      for (final wp in importedWps) {
        if (wp.trackIndex < importedDists.length) {
          importedWaypointGlobalDists.add(importedDists[wp.trackIndex]);
        }
      }
    }

    final hasReal = chartPastAlts.isNotEmpty;
    final hasFuture = futureAlts.isNotEmpty;
    // lib/screens/elevations/elevation_profile_screen.dart (BLOC 2 DE 2)
    // ESTADÍSTIQUES DEL TRAM SELECCIONAT
    double? rangeDistance;
    double? rangeAscent;
    double? rangeDescent;
    Duration? rangeTime;

    if (selectedIndexStart != null &&
        selectedIndexEnd != null &&
        globalDists.isNotEmpty &&
        globalAlts.isNotEmpty) {
      final start = selectedIndexStart;
      final end = selectedIndexEnd;
      if (start < 0 || end < 0) {
        rangeDistance = null;
      } else {
        final safeStart = start.clamp(0, globalDists.length - 1);
        final safeEnd = end.clamp(0, globalDists.length - 1);
        final rangeStart = safeStart < safeEnd ? safeStart : safeEnd;
        final rangeEnd = safeStart > safeEnd ? safeStart : safeEnd;

        rangeDistance = (globalDists[rangeEnd] - globalDists[rangeStart]).abs();

        double ascent = 0;
        double descent = 0;

        for (int i = rangeStart + 1; i <= rangeEnd; i++) {
          final diff = globalAlts[i] - globalAlts[i - 1];
          if (diff > 0) ascent += diff;
          if (diff < 0) descent += diff.abs();
        }

        rangeAscent = ascent;
        rangeDescent = descent;

        if (real.timestamps.length > rangeEnd &&
            real.timestamps.length > rangeStart) {
          final t0 = real.timestamps[rangeStart];
          final t1 = real.timestamps[rangeEnd];
          rangeTime = t1.difference(t0);
        }
      }
    }

    final Set<int> allWpIndexes = {
      ...recordedWps.map((w) => w.trackIndex),
      ...importedWps.map((w) => w.trackIndex),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          t.elevationProfile,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          HeaderLegendWidget(
            hasReal: hasReal,
            hasImported: hasFuture,
            primaryIsReal: true,
            rangeStartIndex: selectedIndexStart,
            rangeEndIndex: selectedIndexEnd,
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            height:
                MediaQuery.of(context).size.height *
                AppDimensions.elevationChartHeightRatio,
            child: ElevationChartWidget(
              // key: const ValueKey("elevation_chart_static_pure"),
              pastAlts: chartPastAlts,
              pastDists: chartPastDists,
              futureAlts: futureAlts,
              futureDistsGlobal: futureDistsGlobal,
              recordedWaypointGlobalDists: recordedWaypointGlobalDists,
              importedWaypointGlobalDists: importedWaypointGlobalDists,
              realColor: trackColor,
              importedColor: importedTrackColor,
              graphNeedleColor: AppColors.primary,
              sliderStartNeedleColor: Colors.green,
              sliderEndNeedleColor: Colors.red,
            ),
          ),

          if (rangeDistance != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.statRangeSelectedTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${t.statRangeDistance}: ${(rangeDistance / 1000).toStringAsFixed(2)} km",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${t.statRangeAscent}: ${rangeAscent!.toStringAsFixed(0)} m",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${t.statRangeDescent}: ${rangeDescent!.toStringAsFixed(0)} m",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (rangeTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${t.statRangeTime}: ${rangeTime.inMinutes} min",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // 🟢 SOLUCIÓ EXPANSIÓ: S'afegeix Expanded per permetre que la llista faci scroll vertical sense trencar el viewport de la Column
          Expanded(
            child: WaypointsListWidget(
              recorded: recordedWps,
              imported: importedWps,
              selectedStartIndex: selectedIndexStart,
              selectedEndIndex: selectedIndexEnd,
              onToggleWaypoint: (wp) => _onToggleWaypoint(wp, allWpIndexes),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
