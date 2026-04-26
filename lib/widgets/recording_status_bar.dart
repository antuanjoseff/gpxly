import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/widgets/floating_route_panel.dart'; // blinkingProvider

class RecordingStatusBar extends ConsumerWidget {
  final RecordingState state;
  final Duration duration;

  const RecordingStatusBar({
    super.key,
    required this.state,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blinking = ref.watch(blinkingProvider).value ?? true;
    // ⛰️ Watch de l'altitud
    final altitude = ref.watch(gpsAltitudeProvider);

    late final Color textColor;
    late final Color iconColor;
    const Color backgroundColor = Colors.white;

    switch (state) {
      case RecordingState.idle:
        textColor = Colors.black;
        iconColor = Colors.black;
        break;
      case RecordingState.recording:
        textColor = Colors.red;
        iconColor = Colors.red;
        break;
      case RecordingState.paused:
        textColor = Colors.green;
        iconColor = Colors.green;
        break;
    }

    Widget icon;
    switch (state) {
      case RecordingState.idle:
        icon = Icon(
          Icons.fiber_manual_record_outlined,
          color: iconColor,
          size: 14,
        );
        break;
      case RecordingState.recording:
        icon = AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blinking ? iconColor : Colors.white,
          ),
        );
        break;
      case RecordingState.paused:
        icon = Icon(Icons.pause, color: iconColor, size: 14);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⏱️ SECCIÓ CRONÒMETRE
          SizedBox(width: 14, height: 14, child: Center(child: icon)),
          const SizedBox(width: 8),
          Text(
            duration.toString().split('.').first.padLeft(8, "0"),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: textColor,
            ),
          ),

          // 📏 SEPARADOR DISCRET
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 14,
            width: 1,
            color: Colors.black12,
          ),

          // ⛰️ SECCIÓ ALTITUD
          const Icon(Icons.terrain, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            "${altitude.toStringAsFixed(0)}m",
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
