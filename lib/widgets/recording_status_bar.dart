import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/floating_route_panel.dart'; // Assegura't que el path sigui correcte

class RecordingStatusBar extends ConsumerWidget {
  final RecordingState state; // 👈 canvi important
  final Duration duration;

  const RecordingStatusBar({
    super.key,
    required this.state,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blinking = ref.watch(blinkingProvider).value ?? true;

    Widget icon;

    switch (state) {
      case RecordingState.idle:
        // 🔵 Encara no hem començat
        icon = const Icon(
          Icons.fiber_manual_record_outlined,
          color: Colors.white,
          size: 14,
        );
        break;

      case RecordingState.recording:
        // 🔴 Blinking
        icon = AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blinking ? Colors.red : Colors.white,
          ),
        );
        break;

      case RecordingState.paused:
        // ⏸️ Pausa
        icon = const Icon(Icons.pause, color: Colors.white, size: 14);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 Icona sempre visible, sempre 14×14
          SizedBox(width: 14, height: 14, child: Center(child: icon)),

          const SizedBox(width: 6),

          // ⏱️ Cronòmetre
          Text(
            duration.toString().split('.').first.padLeft(8, "0"),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
