import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';

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
    final blinking = ref.watch(blinkingProvider).value ?? true;

    // 🎨 Colors segons estat
    final Color textColor = isRecording
        ? Colors
              .red // 🔴 gravant
        : duration.inSeconds > 0
        ? Colors
              .green // 🟢 pausa
        : Colors.black; // ⚫ estat inicial

    final Color dotColor = isRecording
        ? (blinking ? Colors.red : Colors.white) // 🔴 parpelleig
        : duration.inSeconds > 0
        ? Colors
              .green // 🟢 pausa
        : Colors.transparent; // sense punt

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, // 🔥 fons blanc
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴🟢 Punt indicador d’estat
          SizedBox(
            width: 14,
            height: 14,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
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
              color: textColor,
            ),
          ),

          // SEPARADOR
          Container(
            height: 10,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.black12,
          ),

          // ALÇADA
          Icon(Icons.terrain, color: textColor, size: 12),
          const SizedBox(width: 3),
          AnimatedAltitudeText(altitude: altitude, textColor: textColor),
        ],
      ),
    );
  }
}

class AnimatedAltitudeText extends StatelessWidget {
  final double altitude;
  final Color textColor;

  const AnimatedAltitudeText({
    super.key,
    required this.altitude,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final String altitudeStr = altitude != 0.0
        ? "${altitude.toStringAsFixed(0)}m"
        : "?m";

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: Text(
        altitudeStr,
        key: ValueKey<String>(altitudeStr),
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: textColor, // 🔥 ara segueix l’estat
        ),
      ),
    );
  }
}
