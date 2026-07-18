// lib/notifiers/segment_stats_notifier.dart (RESTAVRAT SENSE TRENCAMENTS)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
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

    final bool isRecording = real.recordingState == RecordingState.recording;
    final bool isFollowing =
        remaining != null && remaining.altitudes.isNotEmpty;

    // 🚀 2. CREACIÓ INTEL·LIGENT I ADAPTATIVA DE LES LLISTES SEFONS EL MODE REAL
    List<double> globalDists;
    List<double> globalAlts;
    List<DateTime> globalTimes;

    if (isRecording && isFollowing) {
      // 🔀 ESCENARI MIXT (GRAVANT + SEGUINT): Concatenació estricta del Passat + Futur
      globalDists = [...real.distances, ...remaining.distances];
      globalAlts = [...real.altitudes, ...remaining.altitudes];
      globalTimes = [...real.timestamps, ...remaining.timestamps];
    } else if (isRecording) {
      // 🔴 NOMÉS GRAVANT: Llistes pures de la gravació en viu
      globalDists = real.distances;
      globalAlts = real.altitudes;
      globalTimes = real.timestamps;
    } else if (imported != null) {
      // 🔵 SENSE GRAVAR (REPÒS): Llistes pures del track importat (Garanteix els 998m nets!)
      globalDists = imported.distances;
      globalAlts = imported.altitudes;
      globalTimes = imported.timestamps;
    } else {
      return SegmentStats.empty;
    }
    if (globalDists.length < 2 ||
        globalAlts.length < 2 ||
        globalTimes.length < 2) {
      return SegmentStats.empty;
    }

    // 🚀 2. ESCOLTEM LA SELECCIÓ (MAPA + GRÀFIC)
    final selection = ref.watch(elevationSelectionProvider);

    int start = 0;
    int end = globalDists.length - 1;

    // 🚀 3. LA CONDICIÓ UNIFICADA BLINDADA
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

    // 📐 4. CÀLCULS DE SENDA
    final distance = (globalDists[end] - globalDists[start]).abs();
    double ascent = 0;
    double descent = 0;

    if (globalAlts.isNotEmpty && start < globalAlts.length) {
      // 🚀 CIRURGIA PAS 1: SUAVITZAT DE MITJANA MÒBIL (Sincronitzat amb Python)
      final List<double> altitudsSuaus = [];
      final int n = globalAlts.length;
      const int finestra = 5;
      const int radi = finestra ~/ 2;

      for (int i = 0; i < n; i++) {
        // Corregim els límits de la finestra eliminant el .clamp per evitar asimetries als extrems
        final int inici = (i - radi) < 0 ? 0 : (i - radi);
        final int fi = (i + radi + 1) > n ? n : (i + radi + 1);

        double suma = 0;
        int comptador = 0;
        for (int j = inici; j < fi; j++) {
          suma += globalAlts[j];
          comptador++;
        }
        altitudsSuaus.add(suma / comptador);
      }

      // 🚀 CIRURGIA PAS 2: CÀLCUL AMB LLINDAR FIX ROBUST (3.5 metres)
      const double elevationThreshold = 3.5;
      double lastValidAlt = altitudsSuaus[start];

      for (int i = start + 1; i <= end; i++) {
        final currentAlt = altitudsSuaus[i];
        final diff = currentAlt - lastValidAlt;

        if (diff.abs() >= elevationThreshold) {
          if (diff > 0) {
            ascent += diff;
          } else {
            descent += diff.abs();
          }
          lastValidAlt = currentAlt;
        }
      }
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

  // 🛡️ RESTAURAT: Es manté per retrocompatibilitat amb altres crides externes de Senda
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
