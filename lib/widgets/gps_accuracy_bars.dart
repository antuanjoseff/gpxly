import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_accuracy_notifier.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart'; // 👈 Importamos el seguidor
import 'package:gpxly/services/location_permission_flow.dart';
import '../utils/gps_accuracy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/ui/app_messages.dart';

class GpsAccuracyBars extends ConsumerWidget {
  final int totalBars;
  const GpsAccuracyBars({super.key, this.totalBars = 5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final level = ref.watch(gpsAccuracyLevelProvider);
    final track = ref.watch(trackProvider);
    final followState = ref.watch(
      trackFollowNotifierProvider,
    ); // 👈 Escuchamos seguimiento
    final accuracy = ref.watch(gpsAccuracyProvider);

    // ───────────────────────────────────────────────
    // 1. SENSE PERMISOS
    // ───────────────────────────────────────────────
    if (!permissions.hasPermission) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final ok = await requestLocationPermissionsUnified(context, ref);

          // 🔥 FORZAMOS REFRESCO: Si el usuario acepta, notificamos al provider
          // para que el widget se redibuje inmediatamente.
          ref.read(permissionsProvider.notifier).checkPermissions();

          if (!ok) return;
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
    // 3. ESTADO ACTIVO: Grabando O Siguiendo
    // ───────────────────────────────────────────────
    // Antes solo miraba track.recording. Ahora mira ambos.
    final bool isActive = track.recording || followState.isFollowing;

    if (!isActive) {
      return _wrapWithAccuracyText(
        bars: _buildBars(0, Colors.white),
        accuracy: null,
      );
    }

    // ───────────────────────────────────────────────
    // 4. LÒGICA NORMAL D’ACCURACY (Se activa si isActive es true)
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

  Widget _wrapWithAccuracyText({required Widget bars, double? accuracy}) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        if (accuracy != null)
          Positioned(
            top: -10,
            left: 0,
            child: Text(
              "${accuracy.round()}m",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
        Padding(padding: const EdgeInsets.only(top: 4), child: bars),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // BARRES (Actualitzat per a millor contrast en AppBar blau)
  // ───────────────────────────────────────────────
  Widget _buildBars(int activeBars, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (index) {
        final active = index < activeBars;
        final height = (index + 1) * 4.0;

        // 🔥 CANVI: Ara les barres inactives són sempre blanques
        // amb una opacitat del 30% per destacar sobre el blau.
        final Color inactiveColor = Colors.white.withAlpha(225);

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
