import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';

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
    return SegmentStats.empty;
  }

  /// 🔥 Funció principal: rep les dades globals i calcula les estadístiques
  void updateStats({
    required List<double> globalDists,
    required List<double> globalAlts,
    required List<DateTime> globalTimes,
  }) {
    // 🔥 Evita modificar providers durant un build
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        updateStats(
          globalDists: globalDists,
          globalAlts: globalAlts,
          globalTimes: globalTimes,
        );
      });
      return;
    }

    final selection = ref.read(elevationSelectionProvider);

    if (globalDists.length < 2 ||
        globalAlts.length < 2 ||
        globalTimes.length < 2) {
      state = SegmentStats.empty;
      return;
    }

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

    state = SegmentStats(
      distanceMeters: distance,
      timeElapsedStr: timeStr,
      avgSpeedStr: speedStr,
      ascentMeters: ascent,
      descentMeters: descent,
    );
  }
}

/// Provider del notifier (Riverpod 2.0)
final segmentStatsProvider =
    NotifierProvider<SegmentStatsNotifier, SegmentStats>(
      SegmentStatsNotifier.new,
    );
