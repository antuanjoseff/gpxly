import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';

import 'package:senda/notifiers/segment_stats_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';

import 'package:senda/screens/elevations/widgets/elevation_chart_widget.dart';

class EmbeddedElevationProfile extends ConsumerWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const EmbeddedElevationProfile({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCollapsed) {
      return const SizedBox.shrink();
    }

    // 🔥 Tracks
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);

    // 🔥 Llistes reals del model Track
    final realDists = real.distances;
    final realAlts = real.altitudes;
    final realTimes = real.timestamps;

    final importedDists = imported?.distances ?? [];
    final importedAlts = imported?.altitudes ?? [];
    final importedTimes = imported?.timestamps ?? [];

    final remainingDists = remaining?.distances ?? [];
    final remainingAlts = remaining?.altitudes ?? [];
    final remainingTimes = remaining?.timestamps ?? [];

    // 🔥 Globals concatenats
    final globalDists = <double>[
      ...realDists,
      ...importedDists,
      ...remainingDists,
    ];

    final globalAlts = <double>[...realAlts, ...importedAlts, ...remainingAlts];

    final globalTimes = <DateTime>[
      ...realTimes,
      ...importedTimes,
      ...remainingTimes,
    ];

    // 🔥 Actualitzem stats
    ref
        .read(segmentStatsProvider.notifier)
        .updateStats(
          globalDists: globalDists,
          globalAlts: globalAlts,
          globalTimes: globalTimes,
        );

    // 🔥 Waypoints
    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    final recordedWaypointDists = recordedWps
        .where((w) => w.trackIndex < globalDists.length)
        .map((w) => globalDists[w.trackIndex])
        .toList();

    final importedWaypointDists = importedWps
        .where((w) => w.trackIndex < globalDists.length)
        .map((w) => globalDists[w.trackIndex])
        .toList();

    return Column(
      children: [
        Expanded(
          child: ElevationChartWidget(
            pastDists: realDists,
            pastAlts: realAlts,
            futureDistsGlobal: [...importedDists, ...remainingDists],
            futureAlts: [...importedAlts, ...remainingAlts],
            realColor: Colors.red,
            importedColor: Colors.orange,
            graphNeedleColor: Colors.blue,
            sliderStartNeedleColor: Colors.green,
            sliderEndNeedleColor: Colors.red,

            // 🔥 Waypoints reals
            recordedWaypointGlobalDists: recordedWaypointDists,
            importedWaypointGlobalDists: importedWaypointDists,
          ),
        ),
      ],
    );
  }
}
