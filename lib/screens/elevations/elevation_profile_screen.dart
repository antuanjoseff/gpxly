import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
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

    final realAlts = real.altitudes;
    final realDists = calculateDistances(real.coordinates);
    final importedAlts = imported?.altitudes ?? [];
    final importedDists = calculateDistances(imported?.coordinates ?? []);

    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedTrackColor = ref.watch(importedTrackSettingsProvider).color;

    final primaryIsReal =
        realDists.isNotEmpty &&
        (importedDists.isEmpty || realDists.last >= importedDists.last);

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
            hasReal: realAlts.isNotEmpty,
            hasImported: importedAlts.isNotEmpty,
            primaryIsReal: primaryIsReal,
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

            // Dins del Container que conté l'ElevationChartWidget
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
              importedColor: importedTrackColor,
              graphNeedleColor: AppColors.primary,
              sliderStartNeedleColor: Colors.green,
              sliderEndNeedleColor: Colors.red,

              // CALLBACKS REQUERITS CORREGITS:
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
