import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class HeaderLegendWidget extends ConsumerWidget {
  final bool hasReal;
  final bool hasImported;
  final bool primaryIsReal;

  final double? rangeDistance;
  final double? rangeAscent;
  final Duration? rangeDuration;

  const HeaderLegendWidget({
    super.key,
    required this.hasReal,
    required this.hasImported,
    required this.primaryIsReal,
    this.rangeDistance,
    this.rangeAscent,
    this.rangeDuration,
  });

  bool get hasRange =>
      rangeDistance != null && rangeAscent != null && rangeDuration != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final live = ref.watch(timerProvider);

    final realDur = _realDuration(real, live);
    final impDur = imported?.duration ?? Duration.zero;

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
                distance: hasRange ? rangeDistance! : real.distance,
                ascent: hasRange ? rangeAscent! : real.ascent,
                descent: real.descent,
                duration: hasRange ? rangeDuration! : realDur,
              ),

            if (hasImported && imported != null)
              _trackLine(
                context,
                color: AppColors.routeTrackColor,
                label: "Ruta",
                distance: hasRange ? rangeDistance! : imported.distance,
                ascent: hasRange ? rangeAscent! : imported.ascent,
                descent: imported.descent,
                duration: hasRange ? rangeDuration! : impDur,
              ),
          ],
        ),
      ),
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
                      "${speed.toStringAsFixed(1)} km/h",
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
