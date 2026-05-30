// lib/widgets/gps_accuracy_bars.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
// ✅ ADAPTAT: Importem els nous proveïdors optimitzats
import 'package:senda/notifiers/recording_notifier.dart'; // Bloc 2: Gravació
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

    // ✅ ADAPTAT: Escoltem de forma eficient els nous estats immutables
    final isRecording = ref.watch(
      trackRecordingProvider.select((t) => t.recording),
    );
    final isFollowing = ref.watch(
      navigationProvider.select((n) => n.isFollowing),
    );

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
    // 2. GPS DESACTIVAT AL DISPOSITIU
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
    // 3. COMPROVACIÓ D'ACTIVITAT (Opcional, desactiva si vols que es mostri sempre)
    // ───────────────────────────────────────────────
    // final bool isActive = isRecording || isFollowing;
    // if (!isActive) {
    //   return _wrapWithAccuracyText(
    //     bars: _buildBars(0, Colors.white),
    //     accuracy: null,
    //   );
    // }

    // ───────────────────────────────────────────────
    // 4. LÒGICA NORMAL D’ACCURACY (Nivells de senyal)
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

    return _wrapWithAccuracyText(
      bars: _buildBars(activeBars, color),
      accuracy: accuracy == 999.0 ? null : accuracy,
    );
  }

  Widget _wrapWithAccuracyText({required Widget bars, double? accuracy}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (accuracy != null)
            Positioned(
              top: -6,
              child: Text(
                "${accuracy.round()}m",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          bars,
        ],
      ),
    );
  }

  Widget _buildBars(int activeBars, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (index) {
        final active = index < activeBars;
        final height = (index + 1) * 4.0;
        final Color inactiveColor = Colors.white.withAlpha(
          75,
        ); // Corregit de 225 a 75 per donar el 30% d'opacitat real real sobre el blau

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
