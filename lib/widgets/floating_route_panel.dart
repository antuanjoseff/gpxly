import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/theme/app_colors.dart'; // Assegura't que el path sigui correcte

final blinkingProvider = StreamProvider<bool>((ref) async* {
  bool visible = true;
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    visible = !visible;
    yield visible;
  }
});

class FloatingRoutePanel extends ConsumerWidget {
  final bool isRecording;
  final Duration duration;

  const FloatingRoutePanel({
    super.key,
    required this.isRecording,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altitude = ref.watch(gpsAltitudeProvider);

    // 🔥 Llegim el parpelleig
    final blinking = ref.watch(blinkingProvider).value ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴 Punt vermell que fa pampallugues
          SizedBox(
            width: 14,
            height: 14,
            child: !isRecording
                ? null
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording
                          ? (blinking ? Colors.red : Colors.white)
                          : Colors.red, // estable quan no grava
                      // border: Border.all(
                      //   color: Colors.red.withAlpha(180),
                      //   width: 1.5,
                      // ),
                    ),
                  ),
          ),

          // CRONÒMETRE
          Text(
            isRecording
                ? duration.toString().split('.').first.padLeft(8, "0")
                : "00:00:00",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
            ),
          ),

          // SEPARADOR
          Container(
            height: 10,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white12,
          ),

          // ALÇADA
          const Icon(Icons.terrain, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            altitude != 0.0 ? "${altitude.toStringAsFixed(0)}m" : "?m",
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
