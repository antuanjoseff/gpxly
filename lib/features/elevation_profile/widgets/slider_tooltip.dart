import 'package:flutter/material.dart';

class SliderTooltip extends StatelessWidget {
  final String distance;
  final String altitude;
  final Color color;

  const SliderTooltip({
    super.key,
    required this.distance,
    required this.altitude,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(6),
      color: color.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              distance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              altitude,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
