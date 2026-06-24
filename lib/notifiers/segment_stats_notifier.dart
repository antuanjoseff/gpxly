// lib/notifiers/segment_stats_notifier.dart (CORREGIT DEFINITIU SENSE BUCLES)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
// 🚀 1. Importem els teus sub-providers de rutes reals de Senda
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
    // 🚀 2. REACTIVITAT AUTOMÀTICA DE SENDA:
    // Escoltem els 3 providers de traçats de forma nativa. Si es carrega un track,
    // el build es torna a executar de manera síncrona i transparent sense penjar l'app.
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

    // 🚀 3. CALCULEM EL RANG CORRECTE DIRECTAMENT DES DEL BUILD
    final selection = ref.watch(elevationSelectionProvider);
    int start = 0;
    int end = globalDists.length - 1;

    if (selection.mode == SelectionMode.range &&
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

    // Executem exactament les teves mateixes fórmules matemàtiques de Senda
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

  /// Es manté el mètode vell buit de cortesia per no trencar cap crida residual de la teva app
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
