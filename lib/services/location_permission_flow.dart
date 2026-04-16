import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/services/permissions_service.dart';
import 'package:gpxly/ui/app_messages.dart';

Future<bool> requestLocationPermissionsUnified(
  BuildContext context,
  WidgetRef ref,
) async {
  // 1) Comprovar GPS + permisos (mateix flux que RecordingHandler.start)
  final status = await PermissionsService.checkGpsAndPermissions();

  // GPS OFF
  if (status == GpsPermissionStatus.gpsOff) {
    final go = await AppMessages.showGpsDisabledDialog(context);
    if (go == true) Geolocator.openLocationSettings();
    return false;
  }

  // PERMISOS DENEGATS
  if (status == GpsPermissionStatus.permissionDenied) {
    // Explicació prèvia (igual que RecordingHandler.start)
    final continuar = await AppMessages.showPermissionExplanation(context);
    if (continuar != true) return false;

    // Flux complet de permisos
    final ok = await PermissionsService.ensurePermissions(context);
    if (!ok) return false;

    // Recarregar estat
    await ref.read(permissionsProvider.notifier).checkPermissions();
  }

  // Si arribem aquí → tot correcte
  return true;
}
