// lib/widgets/gps_accuracy_bars.dart (Bloc 1 de 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/services/location_permission_flow.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/utils/gps_accuracy.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);

    // ───────────────────────────────────────────────
    // 1. SENSE PERMISOS
    // ───────────────────────────────────────────────
    if (!permissions.hasPermission) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final ok = await requestLocationPermissionsUnified(context, ref);
          final permNotifier = ref.read(permissionsProvider.notifier);
          await permNotifier.checkPermissions();
          await permNotifier.checkServiceStatus();
          if (!ok) return;
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
    // 2. GPS DESACTIVAT AL MAQUINARI
    // ───────────────────────────────────────────────
    if (!permissions.serviceEnabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final go = await AppMessages.showGpsDisabledDialog(context);
          if (go == true) {
            await Geolocator.openLocationSettings();
            await ref.read(permissionsProvider.notifier).checkServiceStatus();
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
    // 3. SELECCIÓ DE FILTRE CROMÀTIC SEGONS SENYAL
    // ───────────────────────────────────────────────
    late Color color;
    late int activeBars;

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
    // (Continuació del mètode build dins de lib/widgets/gps_accuracy_bars.dart - Bloc 2 de 2)
    final bool showText = accuracy != null && accuracy != 999.0;

    // 🟢 RESTAURAT: Retornem l'antic Stack de mides exactes amb clip invisible de fons [INDEX]
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip
            .none, // Permet que el text surti de la caixa sense retallar-se [INDEX]
        children: [
          // A) El text de metres flotant a dalt de tot a l'esquerra, exactament com abans [INDEX]
          if (showText)
            Positioned(
              left:
                  10, // Desplaçat cap a l'esquerra a sobre de les barres [INDEX]
              top: 10, // Desplaçat cap a dalt de tot [INDEX]
              child: Text(
                "${accuracy.round()}m",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),

          // B) Les barres de cobertura verticals sòlides inferiors [INDEX]
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(totalBars, (index) {
              final active = index < activeBars;
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
    );
  }
}

class GpsDisabledIcon extends StatelessWidget {
  const GpsDisabledIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
      child: const Center(
        child: Icon(Icons.location_off, size: 20, color: Colors.redAccent),
      ),
    );
  }
}
