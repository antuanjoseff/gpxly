import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/features/elevation_profile/widgets/elevation_chart_widget.dart';
import 'package:senda/features/elevation_profile/widgets/header_legend_widget.dart';
import 'package:senda/features/elevation_profile/widgets/waypoints_list_widget.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
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
  int? selectedIndexGraph;
  int? selectedIndexStart;
  int? selectedIndexEnd;

  // ------------------------------------------------------------
  // Helpers per calcular stats del segment
  // ------------------------------------------------------------
  double? _calcSegmentDistance(List<double> dists) {
    if (selectedIndexStart == null || selectedIndexEnd == null) return null;
    final s = selectedIndexStart!;
    final e = selectedIndexEnd!;
    if (s < 0 || e < 0 || s >= dists.length || e >= dists.length) return null;
    return (dists[e] - dists[s]).abs();
  }

  double? _calcSegmentAscent(List<double> alts) {
    if (selectedIndexStart == null || selectedIndexEnd == null) return null;
    final s = selectedIndexStart!;
    final e = selectedIndexEnd!;
    if (s < 0 || e < 0 || s >= alts.length || e >= alts.length) return null;

    double gain = 0;
    final start = s < e ? s : e;
    final end = s < e ? e : s;

    for (int i = start; i < end; i++) {
      final diff = alts[i + 1] - alts[i];
      if (diff > 0) gain += diff;
    }
    return gain;
  }

  Duration? _calcSegmentDuration(List<DateTime>? times) {
    if (times == null) return null;
    if (selectedIndexStart == null || selectedIndexEnd == null) return null;

    final s = selectedIndexStart!;
    final e = selectedIndexEnd!;
    if (s < 0 || e < 0 || s >= times.length || e >= times.length) return null;

    final start = s < e ? s : e;
    final end = s < e ? e : s;

    return times[end].difference(times[start]);
  }

  double? _calcAvgSpeed(double? distMeters, Duration? dur) {
    if (distMeters == null || dur == null) return null;
    final hours = dur.inSeconds / 3600.0;
    if (hours <= 0) return null;
    return (distMeters / 1000.0) / hours;
  }

  // ------------------------------------------------------------
  // Waypoints → callbacks
  // ------------------------------------------------------------
  void _onSetStartFromWaypoint(Waypoint wp) {
    setState(() {
      selectedIndexGraph = null;
      if (selectedIndexEnd != null) {
        final end = selectedIndexEnd!;
        final s = wp.trackIndex < end ? wp.trackIndex : end;
        final e = wp.trackIndex < end ? end : wp.trackIndex;
        selectedIndexStart = s;
        selectedIndexEnd = e;
      } else {
        selectedIndexStart = wp.trackIndex;
      }
    });
  }

  void _onSetEndFromWaypoint(Waypoint wp) {
    setState(() {
      if (selectedIndexStart != null) {
        final start = selectedIndexStart!;
        final s = start < wp.trackIndex ? start : wp.trackIndex;
        final e = start < wp.trackIndex ? wp.trackIndex : start;
        selectedIndexStart = s;
        selectedIndexEnd = e;
        selectedIndexGraph = null;
        return;
      }

      if (selectedIndexGraph != null) {
        final needle = selectedIndexGraph!;
        final s = needle < wp.trackIndex ? needle : wp.trackIndex;
        final e = needle < wp.trackIndex ? wp.trackIndex : needle;
        selectedIndexStart = s;
        selectedIndexEnd = e;
        selectedIndexGraph = null;
        return;
      }

      selectedIndexEnd = wp.trackIndex;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);

    final realAlts = real.altitudes;
    final realDists = calculateDistances(real.coordinates);

    final importedAlts = imported?.altitudes ?? <double>[];
    final importedDists = calculateDistances(imported?.coordinates ?? []);

    final hasReal = realAlts.isNotEmpty;
    final hasImported = importedAlts.isNotEmpty;

    if (!hasReal && !hasImported) {
      return Scaffold(
        appBar: AppBar(title: Text(t.elevationProfile)),
        body: Center(child: Text(t.noData)),
      );
    }

    final primaryIsReal =
        realDists.isNotEmpty &&
        (importedDists.isEmpty || realDists.last >= importedDists.last);

    final primaryAlts = primaryIsReal ? realAlts : importedAlts;
    final primaryDists = primaryIsReal ? realDists : importedDists;

    final secondaryAlts = primaryIsReal ? importedAlts : realAlts;
    final secondaryDists = primaryIsReal ? importedDists : realDists;

    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedColor = ref.watch(importedTrackSettingsProvider).color;

    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    // ------------------------------------------------------------
    // Calcular stats del segment
    // ------------------------------------------------------------
    final segDist = _calcSegmentDistance(primaryDists);
    final segAscent = _calcSegmentAscent(primaryAlts);
    final segDur = _calcSegmentDuration(
      primaryIsReal ? real.timestamps : imported?.timestamps,
    );
    final segSpeed = _calcAvgSpeed(segDist, segDur);

    return Scaffold(
      appBar: AppBar(title: Text(t.elevationProfile)),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ------------------------------------------------------------
          // HEADER + LLEGENDA
          // ------------------------------------------------------------
          HeaderLegendWidget(
            hasReal: hasReal,
            hasImported: hasImported,
            primaryIsReal: primaryIsReal,
            rangeStartIndex: selectedIndexStart,
            rangeEndIndex: selectedIndexEnd,
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------------
          // GRÀFIC
          // ------------------------------------------------------------
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: ElevationChartWidget(
                realAlts: realAlts,
                realDists: realDists,
                importedAlts: importedAlts,
                importedDists: importedDists,
                primaryIsReal: primaryIsReal,
                selectedIndexStart: selectedIndexStart,
                selectedIndexEnd: selectedIndexEnd,
                selectedIndexGraph: selectedIndexGraph,
                recordedWaypointIndices: recordedWps
                    .map((wp) => wp.trackIndex)
                    .toList(),
                importedWaypointIndices: importedWps
                    .map((wp) => wp.trackIndex)
                    .toList(),
                realColor: trackColor,
                importedColor: importedColor,
                graphNeedleColor: Theme.of(context).colorScheme.primary,
                sliderStartNeedleColor: AppColors.trackGreen,
                sliderEndNeedleColor: AppColors.redAlert,
                onNeedleMove: (idx) => setState(() => selectedIndexGraph = idx),
                onRangeSelected: (s, e) {
                  setState(() {
                    selectedIndexStart = s;
                    selectedIndexEnd = e;
                    selectedIndexGraph = null;
                  });
                },
                onClearSelection: () {
                  setState(() {
                    selectedIndexStart = null;
                    selectedIndexEnd = null;
                    selectedIndexGraph = null;
                  });
                },
              ),
            ),
          ),

          // ------------------------------------------------------------
          // WAYPOINTS
          // ------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              child: WaypointsListWidget(
                recorded: recordedWps,
                imported: importedWps,
                selectedStartIndex: selectedIndexStart,
                selectedEndIndex: selectedIndexEnd,
                onSetStart: _onSetStartFromWaypoint,
                onSetEnd: _onSetEndFromWaypoint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
