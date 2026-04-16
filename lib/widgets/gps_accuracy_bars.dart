import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/location_permission_flow.dart';
import 'package:gpxly/services/permissions_service.dart';
import '../utils/gps_accuracy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/ui/app_messages.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);
    final track = ref.watch(trackProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);

    print(
      "🔍 hasPermission=${permissions.hasPermission}, gpsEnabled=${permissions.serviceEnabled}",
    );

    // ───────────────────────────────────────────────
    // 1. SENSE PERMISOS
    // ───────────────────────────────────────────────
    if (!permissions.hasPermission) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final ok = await requestLocationPermissionsUnified(context, ref);
          if (!ok) return;

          // Si vols fer alguna acció extra quan ja hi ha permisos:
          print("🎉 Permisos OK des de la icona!");
        },

        child: Container(
          padding: const EdgeInsets.all(6),
          child: const Tooltip(
            message: "Cal acceptar permisos de localització",
            child: GpsDisabledIcon(),
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────
    // 2. GPS DESACTIVAT
    // ───────────────────────────────────────────────
    if (!permissions.serviceEnabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          print("🔥 TAP: GPS DESACTIVAT");
          final go = await AppMessages.showGpsDisabledDialog(context);
          if (go == true) {
            Geolocator.openLocationSettings();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          child: const Tooltip(
            message: "El GPS està desactivat",
            child: GpsDisabledIcon(),
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────
    // 3. NO S’ESTÀ GRAVANT → barres apagades sense text
    // ───────────────────────────────────────────────
    if (!track.recording) {
      return _wrapWithAccuracyText(
        bars: _buildBars(0, Colors.grey.shade400),
        accuracy: null,
      );
    }

    // ───────────────────────────────────────────────
    // 4. LÒGICA NORMAL D’ACCURACY
    // ───────────────────────────────────────────────
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

    return _wrapWithAccuracyText(
      bars: _buildBars(activeBars, color),
      accuracy: accuracy == 999.0 ? null : accuracy,
    );
  }

  // ───────────────────────────────────────────────
  // COMBINA BARRES + TEXT
  // ───────────────────────────────────────────────
  Widget _wrapWithAccuracyText({required Widget bars, double? accuracy}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bars,
        if (accuracy != null) ...[
          const SizedBox(width: 4),
          Text(
            "${accuracy.round()}m",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────
  // BARRES
  // ───────────────────────────────────────────────
  Widget _buildBars(int activeBars, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (index) {
        final active = index < activeBars;
        final height = (index + 1) * 4.0;

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
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
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
