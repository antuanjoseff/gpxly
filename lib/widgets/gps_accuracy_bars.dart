import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import '../utils/gps_accuracy.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(gpsAccuracyLevelProvider);
    final track = ref.watch(trackProvider);

    Color color;
    int activeBars;

    if (!track.recording) {
      color = Colors.grey.shade400;
      activeBars = 0;
    } else {
      switch (level) {
        case GpsAccuracyLevel.excellent:
          color = const Color(0xFF00FF66); // Verd neó
          activeBars = totalBars;
          break;

        case GpsAccuracyLevel.good:
          color = const Color(0xFF00E676); // Verd brillant
          activeBars = (totalBars * 0.8).ceil();
          break;

        case GpsAccuracyLevel.medium:
          color = const Color(0xFFFFA726); // Taronja intens
          activeBars = (totalBars * 0.6).ceil();
          break;

        case GpsAccuracyLevel.poor:
          color = const Color(0xFFFF7043); // Taronja-vermell
          activeBars = (totalBars * 0.4).ceil();
          break;

        case GpsAccuracyLevel.bad:
          color = const Color(0xFFFF1744); // Vermell brillant
          activeBars = 1;
          break;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (index) {
        final active = index < activeBars;
        final height = (index + 1) * 4.0;
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? color : color.withAlpha((0.3 * 255).round()),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
