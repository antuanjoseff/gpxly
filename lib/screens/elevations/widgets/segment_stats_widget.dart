import 'package:flutter/material.dart';
import 'package:strack_rec/theme/app_colors.dart';

class SegmentStatsWidget extends StatelessWidget {
  final double distanceMeters;
  final String timeElapsedStr;
  final String avgSpeedStr;
  final double ascentMeters;
  final double descentMeters;
  final VoidCallback? onTap;

  const SegmentStatsWidget({
    super.key,
    required this.distanceMeters,
    required this.timeElapsedStr,
    required this.avgSpeedStr,
    required this.ascentMeters,
    required this.descentMeters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.dark.withAlpha(150),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat(
                      icon: Icons.straighten,
                      color: Colors.white70,
                      text: "${(distanceMeters / 1000).toStringAsFixed(2)}km",
                    ),
                    _stat(
                      icon: Icons.access_time_rounded,
                      color: Colors.amberAccent,
                      text: timeElapsedStr,
                    ),
                    _stat(
                      icon: Icons.speed_rounded,
                      color: Colors.cyanAccent,
                      text: avgSpeedStr,
                    ),
                    _stat(
                      icon: Icons.arrow_upward,
                      color: Colors.greenAccent,
                      text: "+${ascentMeters.toStringAsFixed(0)}m",
                    ),
                    _stat(
                      icon: Icons.arrow_downward,
                      color: Colors.redAccent,
                      text: "-${descentMeters.toStringAsFixed(0)}m",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
