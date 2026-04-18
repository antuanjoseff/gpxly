import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/floating_route_panel.dart'; // Assegura't que el path sigui correcte

class FloatingAltitudePanel extends ConsumerWidget {
  const FloatingAltitudePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const Icon(Icons.terrain, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          AnimatedAltitudeText(altitude: altitude, textColor: AppColors.white),
        ],
      ),
    );
  }
}
