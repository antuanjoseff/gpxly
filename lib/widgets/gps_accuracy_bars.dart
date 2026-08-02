// lib/widgets/gps_accuracy_bars.dart (Bloc 1 de 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:strack_rec/notifiers/gps_accuracy_notifier.dart';
import 'package:strack_rec/notifiers/permissions_notifier.dart';
import 'package:strack_rec/services/location_permission_flow.dart';
import 'package:strack_rec/ui/app_messages.dart';
import 'package:strack_rec/utils/gps_accuracy.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);

    final bool isGpsReady =
        permissions.hasPermission && permissions.serviceEnabled;

    late Color color;
    int activeBars = 0; // Per defecte 0 si el GPS està apagat

    if (isGpsReady) {
      switch (level) {
        case GpsAccuracyLevel.high:
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
    }

    // El text dels metres només es mostra si el GPS funciona i rep dades reals
    final bool showText = isGpsReady && accuracy != 999.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        // 🟢 ACCIÓ ADAPTATIVA MULTI-ESTAT:
        if (!permissions.hasPermission) {
          final ok = await requestLocationPermissionsUnified(context, ref);
          final permNotifier = ref.read(permissionsProvider.notifier);
          await permNotifier.checkPermissions();
          await permNotifier.checkServiceStatus();
        } else if (!permissions.serviceEnabled) {
          final go = await AppMessages.showGpsDisabledDialog(context);
          if (go == true) {
            await Geolocator.openLocationSettings();
            await ref.read(permissionsProvider.notifier).checkServiceStatus();
          }
        }
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // A) El text de metres flotant a dalt de tot a l'esquerra
            if (showText)
              Positioned(
                left: 0,
                top: 0,
                child: Text(
                  "${accuracy.round()}m",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),

            // B) Les barres de cobertura verticals (S'apaguen en gris fi si no hi ha GPS)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(totalBars, (index) {
                final active = isGpsReady && index < activeBars;
                final height = (index + 1) * 4.0;
                final Color inactiveColor = Colors.white.withAlpha(75);

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
            ),
          ],
        ),
      ),
    );
  }
}
