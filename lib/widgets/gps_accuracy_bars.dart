import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import '../utils/gps_accuracy.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);
    final track = ref.watch(trackProvider);

    // 1. Sense permisos
    if (!permissions.hasPermission) {
      return const Tooltip(
        message: "Cal acceptar permisos de localització",
        child: GpsDisabledIcon(),
      );
    }

    // 2. GPS desactivat
    if (!permissions.serviceEnabled) {
      return const Tooltip(
        message: "El GPS està desactivat",
        child: GpsDisabledIcon(),
      );
    }

    // 3. Gravació no activa
    if (!track.recording) {
      return _buildBars(0, Colors.grey.shade400);
    }

    // 4. Lògica normal d’accuracy
    late Color color;
    late int activeBars;

    switch (level) {
      case GpsAccuracyLevel.excellent:
        color = const Color(0xFF00FF66);
        activeBars = totalBars;
        break;
      case GpsAccuracyLevel.good:
        color = const Color(0xFF00E676);
        activeBars = (totalBars * 0.8).ceil();
        break;
      case GpsAccuracyLevel.medium:
        color = const Color(0xFFFFA726);
        activeBars = (totalBars * 0.6).ceil();
        break;
      case GpsAccuracyLevel.poor:
        color = const Color(0xFFFF7043);
        activeBars = (totalBars * 0.4).ceil();
        break;
      case GpsAccuracyLevel.bad:
        color = const Color(0xFFFF1744);
        activeBars = 1;
        break;
    }

    return _buildBars(activeBars, color);
  }

  Widget _buildBars(int activeBars, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (index) {
        final active = index < activeBars;
        final height = (index + 1) * 4.0;

        // 0.3 opacity → alpha 77
        final inactiveColor = color.withAlpha(77);

        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? color : inactiveColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class GpsDisabledIcon extends StatelessWidget {
  const GpsDisabledIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, // cercle blanc opac
        shape: BoxShape.circle,
        boxShadow: [
          // 0.15 opacity → alpha 38
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(Icons.location_off, size: 14, color: Colors.redAccent),
    );
  }
}
