import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:strack_rec/notifiers/permissions_notifier.dart';
import 'package:strack_rec/services/permissions_service.dart';
import 'package:strack_rec/ui/app_messages.dart';
import 'package:permission_handler/permission_handler.dart'; // Imprescindible per a openAppSettings

Future<bool> requestLocationPermissionsUnified(
  BuildContext context,
  WidgetRef ref,
) async {
  // 1) Comprovar estat actual
  final status = await PermissionsService.checkGpsAndPermissions();

  // --- GPS OFF ---
  if (status == GpsPermissionStatus.gpsOff) {
    final go = await AppMessages.showGpsDisabledDialog(context);
    if (go == true) Geolocator.openLocationSettings();
    return false;
  }

  // --- PERMISOS DENEGATS O BLOQUEJATS ---
  if (status == GpsPermissionStatus.permissionDenied) {
    // 🔥 MILLORA: Mirem si el permís està bloquejat permanentment (per haver dit 'enrere' 2 cops)
    final isPermanentlyDenied =
        await Permission.locationAlways.isPermanentlyDenied;

    if (isPermanentlyDenied) {
      // Si està bloquejat, el pop-up de sistema ja no sortirà.
      // Mostrem el diàleg que avisa que cal anar a la configuració manual.
      final goSettings = await AppMessages.showLocationPermissionDialog(
        context,
      );
      if (goSettings == true) {
        await openAppSettings(); // Obre la pantalla de l'app dins d'Ajustos
      }
      return false;
    }

    // Si NO està bloquejat permanentment, fem el flux normal
    final continuar = await AppMessages.showPermissionExplanation(context);
    if (continuar != true) return false;

    final ok = await PermissionsService.ensurePermissions(context);
    if (!ok) return false;

    // Recarregar estat del provider
    await ref.read(permissionsProvider.notifier).checkPermissions();
  }

  return true;
}
