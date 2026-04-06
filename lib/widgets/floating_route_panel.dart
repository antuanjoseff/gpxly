import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/theme/app_colors.dart'; // Assegura't que el path sigui correcte

class FloatingRoutePanel extends ConsumerWidget {
  // Canviem a ConsumerWidget
  final bool isRecording;
  final Duration duration;

  const FloatingRoutePanel({
    super.key,
    required this.isRecording,
    required this.duration,
    // Eliminem l'altitude dels paràmetres
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Afegim WidgetRef
    // Llegim l'altitud directament del provider
    final altitude = ref.watch(gpsAltitudeProvider);

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
          // CRONÒMETRE COMPACTE
          Text(
            isRecording
                ? duration.toString().split('.').first.padLeft(8, "0")
                : "00:00:00",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isRecording ? Colors.white : Colors.white,
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
          const Icon(Icons.terrain, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            // Ara usem la variable que ve del provider
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
