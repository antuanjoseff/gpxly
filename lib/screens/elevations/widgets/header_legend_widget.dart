// lib/screens/elevations/widgets/header_legend_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
// ✅ ADAPTAT: Importem el nou proveïdor de gravació
import 'package:strack_rec/notifiers/recording_notifier.dart'; // Bloc 2: Gravació neta
import 'package:strack_rec/notifiers/timer_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/utils/calculations.dart';
import 'package:strack_rec/utils/distance_utils.dart';

class HeaderLegendWidget extends ConsumerWidget {
  final bool hasReal;
  final bool hasImported;
  final bool primaryIsReal;

  final int? rangeStartIndex;
  final int? rangeEndIndex;

  const HeaderLegendWidget({
    super.key,
    required this.hasReal,
    required this.hasImported,
    required this.primaryIsReal,
    this.rangeStartIndex,
    this.rangeEndIndex,
  });

  bool get hasRange => rangeStartIndex != null && rangeEndIndex != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ADAPTAT: Llegim el nou trackRecordingProvider unificat de la branca
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final live = ref.watch(timerProvider);

    final realDur = _realDuration(real, live);
    final impDur = imported?.duration ?? Duration.zero;

    // ─────────────────────────────────────────────
    // CÀLCUL DEL RANG PER CADA TRACK
    // ─────────────────────────────────────────────
    _RangeStats? realRange;
    _RangeStats? importedRange;

    if (hasRange) {
      final s = rangeStartIndex!;
      final e = rangeEndIndex!;

      realRange = _computeRange(real, s, e);

      if (imported != null) {
        importedRange = _computeRange(imported, s, e);
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasReal)
              _trackLine(
                context,
                color: AppColors.recordingTrackColor,
                label: "Gravat",
                distance: realRange?.distance ?? real.distance,
                ascent: realRange?.ascent ?? real.ascent,
                descent: realRange?.descent ?? real.descent,
                duration: realRange?.duration ?? realDur,
              ),

            if (hasImported && imported != null)
              _trackLine(
                context,
                color: AppColors.routeTrackColor,
                label: "Ruta",
                distance: importedRange?.distance ?? imported.distance,
                ascent: importedRange?.ascent ?? imported.ascent,
                descent: importedRange?.descent ?? imported.descent,
                duration: importedRange?.duration ?? impDur,
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CÀLCUL DEL RANG PER UN TRACK
  // ─────────────────────────────────────────────
  _RangeStats _computeRange(Track t, int s, int e) {
    // ✅ ADAPTAT: Llegim de forma compatible usant les propietats simulades del model
    if (s < 0 || e >= t.distances.length) {
      return const _RangeStats.empty();
    }

    final dist = (t.distances[e] - t.distances[s]).abs();

    final subAlts = t.altitudes.sublist(s, e + 1);
    final subDists = t.distances.sublist(s, e + 1);
    final gain = ElevationUtils.computeGain(subAlts, distances: subDists);
    final ascent = gain.ascent;
    final descent = gain.descent;

    // Durada proporcional (simple i suficient)
    final duration = Duration(
      seconds:
          (t.duration.inSeconds * (dist / t.distance.clamp(1, double.infinity)))
              .round(),
    );

    return _RangeStats(
      distance: dist,
      ascent: ascent,
      descent: descent,
      duration: duration,
    );
  }

  Duration _realDuration(Track real, Duration live) {
    switch (real.recordingState) {
      case RecordingState.recording:
        return live;
      case RecordingState.paused:
        return real.duration;
      default:
        return Duration.zero;
    }
  }

  double _speed(double dist, Duration dur) {
    final h = dur.inSeconds / 3600;
    if (h <= 0) return 0;
    return (dist / 1000) / h;
  }

  Widget _trackLine(
    BuildContext context, {
    required Color color,
    required String label,
    required double distance,
    required double ascent,
    required double descent,
    required Duration duration,
  }) {
    final speed = _speed(distance, duration);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTrackDetails(
        context,
        label,
        distance,
        ascent,
        descent,
        duration,
        speed,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            _dot(color),
            const SizedBox(width: 6),

            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),

            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.black26,
            ),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDistance(distance),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Text(" · ", style: TextStyle(color: Colors.black54)),

                  Expanded(
                    child: Text(
                      "+${ascent.toStringAsFixed(0)} m / -${descent.toStringAsFixed(0)} m",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const Text(" · ", style: TextStyle(color: Colors.black54)),

                  Expanded(
                    child: Text(
                      _fmt(duration),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const Text(" · ", style: TextStyle(color: Colors.black54)),

                  Expanded(
                    child: Text(
                      "${_speed(distance, duration).toStringAsFixed(1)} km/h",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackDetails(
    BuildContext context,
    String label,
    double distance,
    double ascent,
    double descent,
    Duration duration,
    double speed,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _infoRow("Distància", formatDistance(distance)),
                _infoRow("Desnivell +", "+${ascent.toStringAsFixed(0)} m"),
                _infoRow("Desnivell -", "-${descent.toStringAsFixed(0)} m"),
                _infoRow("Durada", _fmt(duration)),
                _infoRow("Velocitat", "${speed.toStringAsFixed(1)} km/h"),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  String _fmt(Duration d) =>
      "${d.inHours.toString().padLeft(2, '0')}:"
      "${(d.inMinutes % 60).toString().padLeft(2, '0')}:"
      "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

class _RangeStats {
  final double distance;
  final double ascent;
  final double descent;
  final Duration duration;

  const _RangeStats({
    required this.distance,
    required this.ascent,
    required this.descent,
    required this.duration,
  });

  const _RangeStats.empty()
    : distance = 0,
      ascent = 0,
      descent = 0,
      duration = Duration.zero;
}
