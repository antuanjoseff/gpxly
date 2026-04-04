import 'package:flutter/material.dart';

class FloatingRoutePanel extends StatelessWidget {
  final bool isRecording;
  final Duration duration;
  final double? altitude;

  const FloatingRoutePanel({
    super.key,
    required this.isRecording,
    required this.duration,
    this.altitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Reduïm padding per fer-lo mínim
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180), // Una mica més transparent
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ocupa només l'espai dels fills
        children: [
          // CRONÒMETRE COMPACTE
          Text(
            isRecording
                ? duration.toString().split('.').first.padLeft(8, "0")
                : "00:00:00",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13, // Mida més petita
              color: isRecording ? const Color(0xFF00E676) : Colors.white24,
            ),
          ),

          // SEPARADOR SUBTIL
          Container(
            height: 10,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white12,
          ),

          // ALÇADA COMPACTA
          const Icon(Icons.terrain, color: Colors.white60, size: 12),
          const SizedBox(width: 3),
          Text(
            altitude != null ? "${altitude!.toStringAsFixed(0)}m" : "?m",
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
