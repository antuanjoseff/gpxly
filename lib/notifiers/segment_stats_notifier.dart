// lib/notifiers/segment_stats_notifier.dart (SOLUCIÓ FINAL DEFINITIVA)
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';

class SegmentStats {
  final double distanceMeters;
  final String timeElapsedStr;
  final String avgSpeedStr;
  final double ascentMeters;
  final double descentMeters;

  const SegmentStats({
    required this.distanceMeters,
    required this.timeElapsedStr,
    required this.avgSpeedStr,
    required this.ascentMeters,
    required this.descentMeters,
  });

  static const empty = SegmentStats(
    distanceMeters: 0,
    timeElapsedStr: "--:--",
    avgSpeedStr: "--.- km/h",
    ascentMeters: 0,
    descentMeters: 0,
  );
}

class SegmentStatsNotifier extends Notifier<SegmentStats> {
  @override
  SegmentStats build() {
    // 🚀 1. ESCOLTEM LES RUTES REALS DE SENDA
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);

    final globalDists = <double>[
      ...real.distances,
      ...?imported?.distances,
      ...?remaining?.distances,
    ];
    final globalAlts = <double>[
      ...real.altitudes,
      ...?imported?.altitudes,
      ...?remaining?.altitudes,
    ];
    final globalTimes = <DateTime>[
      ...real.timestamps,
      ...?imported?.timestamps,
      ...?remaining?.timestamps,
    ];

    if (globalDists.length < 2 ||
        globalAlts.length < 2 ||
        globalTimes.length < 2) {
      return SegmentStats.empty;
    }

    // 🚀 2. ESCOLTEM LA SELECCIÓ (MAPA + GRÀFIC)
    // Cada cop que l'usuari toqui el mapa o el gràfic, aquest build es tornarà a executar
    // de forma automàtica, síncrona i transparent, tinguis o no el perfil obert!
    final selection = ref.watch(elevationSelectionProvider);

    int start = 0;
    int end = globalDists.length - 1;

    // 🚀 3. LA CONDICIÓ UNIFICADA BLINDADA:
    // Retallem el tram si estem en mode range, o si l'eina del mapa ha completat la selecció (selected)
    final bool hiHaTram =
        (selection.mode == SelectionMode.range) ||
        (selection.mapToolState == MapSelectionToolState.selected);

    if (hiHaTram &&
        selection.startTrackIndex != null &&
        selection.endTrackIndex != null) {
      start = selection.startTrackIndex!.clamp(0, globalDists.length - 1);
      end = selection.endTrackIndex!.clamp(0, globalDists.length - 1);
      if (start > end) {
        final tmp = start;
        start = end;
        end = tmp;
      }
    }

    // 📐 4. CÀLCULS DE SENDA (Idèntics a les teves fórmules)
    final distance = (globalDists[end] - globalDists[start]).abs();
    double ascent = 0;
    double descent = 0;

    for (int i = start + 1; i <= end; i++) {
      final diff = globalAlts[i] - globalAlts[i - 1];
      if (diff > 0) ascent += diff;
      if (diff < 0) descent += diff.abs();
    }

    String timeStr = "--:--";
    String speedStr = "--.- km/h";

    if (start < globalTimes.length && end < globalTimes.length) {
      final duration = globalTimes[end].difference(globalTimes[start]).abs();
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60);
      final s = duration.inSeconds.remainder(60);

      if (h > 0) {
        timeStr = "${h}h ${m.toString().padLeft(2, '0')}m";
      } else {
        timeStr = "$m:${s.toString().padLeft(2, '0')}";
      }

      if (duration.inSeconds > 0 && distance > 0) {
        final speedMps = distance / duration.inSeconds;
        final speedKmh = speedMps * 3.6;
        speedStr = "${speedKmh.toStringAsFixed(1)} km/h";
      }
    }

    return SegmentStats(
      distanceMeters: distance,
      timeElapsedStr: timeStr,
      avgSpeedStr: speedStr,
      ascentMeters: ascent,
      descentMeters: descent,
    );
  }

  void updateStats({
    required List<double> globalDists,
    required List<double> globalAlts,
    required List<DateTime> globalTimes,
  }) {}
}

final segmentStatsProvider =
    NotifierProvider<SegmentStatsNotifier, SegmentStats>(
      SegmentStatsNotifier.new,
    );
