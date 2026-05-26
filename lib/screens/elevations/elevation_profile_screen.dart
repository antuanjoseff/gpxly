// lib/screens/elevations/elevation_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/notifiers/track_follow_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/screens/elevations/widgets/elevation_chart_widget.dart';
import 'package:senda/screens/elevations/widgets/header_legend_widget.dart';
import 'package:senda/screens/elevations/widgets/waypoints_list_widget.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? selectedIndexGraph;

  void _onToggleWaypoint(Waypoint wp) {
    final int idx = wp.trackIndex;
    setState(() {
      selectedIndexGraph = null;
      if (selectedIndexStart == idx) {
        selectedIndexStart = null;
      } else if (selectedIndexEnd == idx) {
        selectedIndexEnd = null;
      } else if (selectedIndexStart == null) {
        selectedIndexStart = idx;
      } else if (selectedIndexEnd == null) {
        selectedIndexEnd = idx;
      } else {
        selectedIndexEnd = idx;
      }

      if (selectedIndexStart != null && selectedIndexEnd != null) {
        if (selectedIndexStart! > selectedIndexEnd!) {
          final temp = selectedIndexStart;
          selectedIndexStart = selectedIndexEnd;
          selectedIndexEnd = temp;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);
    final follow = ref.watch(trackFollowNotifierProvider);

    final realAlts = real.altitudes;
    final realDists = calculateDistances(real.coordinates);

    final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;

    // ─────────────────────────────────────────────
    // 1) Lògica principal: quan s'ha de mostrar el FUTUR?
    // ─────────────────────────────────────────────
    final bool shouldShowFuture =
        follow.isFollowing && !follow.isOffTrack && remaining != null;

    // ─────────────────────────────────────────────
    // 2) FUTUR segons la lògica final + ESCALAT 20%
    // ─────────────────────────────────────────────
    late List<double> futureAlts;
    late List<double> futureDistsGlobal;

    if (shouldShowFuture) {
      // NOVA LÒGICA: futur enganxat al track real
      futureAlts = remaining!.altitudes;
      futureDistsGlobal = remaining.distances
          .map((d) => pastLastDist + d)
          .toList(growable: false);
    } else {
      // COMPORTAMENT ANTIC: track importat complet (si existeix)
      final importedDists = calculateDistances(imported?.coordinates ?? []);
      futureAlts = imported?.altitudes ?? [];
      futureDistsGlobal = importedDists;
    }

    // ─────────────────────────────────────────────
    // 2B) ESCALAT DEL FUTUR AL 20% DEL GRÀFIC
    // ─────────────────────────────────────────────
    if (futureDistsGlobal.isNotEmpty && realDists.isNotEmpty) {
      final double maxPast = realDists.last;
      final double maxFuture = futureDistsGlobal.last;

      if (maxFuture > 0) {
        // El futur ha d'ocupar només el 20% de l'amplada total
        final double futureScale =
            (maxPast * TrackThresholds.futureTrackVisibility) / maxFuture;

        futureDistsGlobal = futureDistsGlobal
            .map((d) => maxPast + d * futureScale)
            .toList(growable: false);
      }
    }

    // Llistes globals (passat + futur)
    final globalDists = <double>[...realDists, ...futureDistsGlobal];
    final globalAlts = <double>[...realAlts, ...futureAlts];
    // ─────────────────────────────────────────────
    // 3) WAYPOINTS
    // ─────────────────────────────────────────────
    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedTrackColor = ref.watch(importedTrackSettingsProvider).color;

    // Waypoints gravats → sempre globals
    final recordedWaypointGlobalDists = recordedWps
        .where((wp) => wp.trackIndex >= 0 && wp.trackIndex < realDists.length)
        .map((wp) => realDists[wp.trackIndex])
        .toList(growable: false);

    // Waypoints importats
    final importedWaypointGlobalDists = <double>[];

    if (!shouldShowFuture) {
      // COMPORTAMENT ANTIC: tots els waypoints importats
      final importedDists = calculateDistances(imported?.coordinates ?? []);
      for (final wp in importedWps) {
        if (wp.trackIndex < importedDists.length) {
          importedWaypointGlobalDists.add(importedDists[wp.trackIndex]);
        }
      }
    } else {
      // NOVA LÒGICA: només waypoints FUTURS
      for (final wp in importedWps) {
        final idx = wp.trackIndex;
        if (idx < remaining!.anchorIndex) continue;

        final futureIdx = idx - remaining.anchorIndex;
        if (futureIdx < remaining.distances.length) {
          importedWaypointGlobalDists.add(
            pastLastDist + remaining.distances[futureIdx],
          );
        }
      }
    }

    final hasReal = realAlts.isNotEmpty;
    final hasFuture = futureAlts.isNotEmpty;

    // ─────────────────────────────────────────────
    // 5) Estadístiques del rang seleccionat
    // ─────────────────────────────────────────────
    double? rangeDistance;
    double? rangeAscent;
    double? rangeDescent;
    Duration? rangeTime;

    if (selectedIndexStart != null && selectedIndexEnd != null) {
      final start = selectedIndexStart!;
      final end = selectedIndexEnd!;

      // 1) Distància
      rangeDistance = (globalDists[end] - globalDists[start]).abs();

      // 2) Desnivell acumulat
      double ascent = 0;
      double descent = 0;

      for (int i = start + 1; i <= end; i++) {
        final diff = globalAlts[i] - globalAlts[i - 1];
        if (diff > 0) ascent += diff;
        if (diff < 0) descent += diff.abs();
      }

      rangeAscent = ascent;
      rangeDescent = descent;

      // 3) Temps (només si tens timestamps)
      final real = ref.watch(trackProvider);
      if (real.timestamps != null &&
          real.timestamps!.length > end &&
          real.timestamps!.length > start) {
        final t0 = real.timestamps![start];
        final t1 = real.timestamps![end];
        rangeTime = t1.difference(t0);
      }
    }

    // ─────────────────────────────────────────────
    // 4) UI (sense canvis)
    // ─────────────────────────────────────────────
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
      body: ListView(
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
            height: MediaQuery.of(context).size.height * 0.32,
            child: ElevationChartWidget(
              pastAlts: realAlts,
              pastDists: realDists,
              futureAlts: futureAlts,
              futureDistsGlobal: futureDistsGlobal,
              selectedIndexStart: selectedIndexStart,
              selectedIndexEnd: selectedIndexEnd,
              selectedIndexGraph: selectedIndexGraph,
              recordedWaypointGlobalDists: recordedWaypointGlobalDists,
              importedWaypointGlobalDists: importedWaypointGlobalDists,
              realColor: trackColor,
              importedColor: importedTrackColor,
              graphNeedleColor: AppColors.primary,
              sliderStartNeedleColor: Colors.green,
              sliderEndNeedleColor: Colors.red,
              onNeedleMove: (idx) => setState(() {
                selectedIndexGraph = idx;
              }),
              onRangeSelected: (start, end) => setState(() {
                selectedIndexStart = start;
                selectedIndexEnd = end;
                selectedIndexGraph = null;
              }),
              onClearSelection: () => setState(() {
                selectedIndexStart = null;
                selectedIndexEnd = null;
                selectedIndexGraph = null;
              }),
            ),
          ),
          if (rangeDistance != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    const Text(
                      "Rang seleccionat",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Distància: ${(rangeDistance! / 1000).toStringAsFixed(2)} km",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "Desnivell +: ${rangeAscent!.toStringAsFixed(0)} m",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "Desnivell -: ${rangeDescent!.toStringAsFixed(0)} m",
                      style: const TextStyle(fontSize: 14),
                    ),

                    if (rangeTime != null)
                      Text(
                        "Temps: ${rangeTime!.inMinutes} min",
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
          WaypointsListWidget(
            recorded: recordedWps,
            imported: importedWps,
            selectedStartIndex: selectedIndexStart,
            selectedEndIndex: selectedIndexEnd,
            onToggleWaypoint: _onToggleWaypoint,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
