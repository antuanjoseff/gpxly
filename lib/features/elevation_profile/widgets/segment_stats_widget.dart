import 'package:flutter/material.dart';
import 'package:senda/utils/distance_utils.dart';

class SegmentStatsWidget extends StatelessWidget {
  final double? distanceMeters;
  final Duration? duration;
  final double? ascentMeters;
  final double? avgSpeedKmh;
  final Color backgroundColor;

  const SegmentStatsWidget({
    super.key,
    required this.distanceMeters,
    required this.duration,
    required this.ascentMeters,
    required this.avgSpeedKmh,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (distanceMeters == null ||
        duration == null ||
        ascentMeters == null ||
        avgSpeedKmh == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _tile(Icons.straighten, formatDistance(distanceMeters!)),
          _tile(Icons.timer, _format(duration!)),
          _tile(Icons.speed, "${avgSpeedKmh!.toStringAsFixed(1)} km/h"),
          _tile(Icons.terrain, "+${ascentMeters!.toStringAsFixed(0)} m"),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}
