// lib/screens/elevations/widgets/embedded_elevation_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
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

    // 🔥 Estados activos de Riverpod
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);

    final realAlts = real.altitudes;
    final realDists = real.distances;
    final realTimes = real.timestamps;
    final bool isRecording = real.recordingState == RecordingState.recording;

    // Determinamos si el usuario está siguiendo activamente el track guiado
    final bool isFollowingActive = remaining != null;

    // 🟢 PIPELINING DE DATOS CONTROLADO: Evitamos duplicar arrays en memoria
    late List<double> chartPastAlts;
    late List<double> chartPastDists;
    late List<double> futureAlts;
    late List<double> futureDistsGlobal;
    late List<DateTime> futureTimes;

    if (isRecording && isFollowingActive) {
      // 1) MODO MIXTO: Grabando y Siguiendo activamente la guía
      chartPastAlts = realAlts;
      chartPastDists = realDists;

      final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
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
      futureTimes = remaining.timestamps;
    } else if (imported != null) {
      // 2) MODO GUÍA PASIVA: Hay un track cargado (estés o no grabando de forma independiente)
      // Mantenemos la guía íntegra para que el eje X no colapse a 1 metro en la Home
      chartPastAlts = realAlts;
      chartPastDists = realDists;
      futureAlts = imported.altitudes;
      futureDistsGlobal = imported.distances;
      futureTimes = imported.timestamps;
    } else {
      // 3) MODO SÓLO GRABACIÓN: No hay ninguna ruta cargada en el mapa
      chartPastAlts = realAlts;
      chartPastDists = realDists;
      futureAlts = const [];
      futureDistsGlobal = const [];
      futureTimes = const [];
    }

    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    // Los waypoints reales se buscan sobre el recorrido grabado real
    final recordedWaypointDists = recordedWps
        .where((w) => w.trackIndex >= 0 && w.trackIndex < realDists.length)
        .map((w) => realDists[w.trackIndex])
        .toList();

    // Los waypoints importados se buscan sobre la lista del recorrido futuro mapeado
    final importedWaypointDists = <double>[];
    if (isRecording && isFollowingActive) {
      final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
      for (final wp in importedWps) {
        final idx = wp.trackIndex;
        if (idx < remaining.anchorIndex) continue;
        final futureIdx = idx - remaining.anchorIndex;
        if (futureIdx < remaining.distances.length) {
          importedWaypointDists.add(
            pastLastDist + remaining.distances[futureIdx],
          );
        }
      }
    } else if (imported != null) {
      for (final wp in importedWps) {
        if (wp.trackIndex >= 0 && wp.trackIndex < imported.distances.length) {
          importedWaypointDists.add(imported.distances[wp.trackIndex]);
        }
      }
    }

    return Column(
      children: [
        Expanded(
          child: ElevationChartWidget(
            pastDists: chartPastDists,
            pastAlts: chartPastAlts,
            futureDistsGlobal: futureDistsGlobal,
            futureAlts: futureAlts,
            realColor: Colors.red,
            importedColor: Colors.orange,
            graphNeedleColor: Colors.blue,
            sliderStartNeedleColor: Colors.green,
            sliderEndNeedleColor: Colors.red,
            recordedWaypointGlobalDists: recordedWaypointDists,
            importedWaypointGlobalDists: importedWaypointDists,
          ),
        ),
      ],
    );
  }
}
