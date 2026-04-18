import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track.dart';
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

    // 🎨 Colors segons estat
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

    // 🔥 Icona segons estat
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
          curve: Curves.easeInOut,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor, // 🤍 fons blanc
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icona sempre 14×14
          SizedBox(width: 14, height: 14, child: Center(child: icon)),

          const SizedBox(width: 6),

          // ⏱️ Cronòmetre
          Text(
            duration.toString().split('.').first.padLeft(8, "0"),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: textColor, // 🎨 color segons estat
            ),
          ),
        ],
      ),
    );
  }
}
