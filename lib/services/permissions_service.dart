import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:strack_rec/services/native_gps_channel.dart';
import 'package:strack_rec/ui/app_messages.dart';

enum GpsPermissionStatus { ok, gpsOff, permissionDenied }

class PermissionsService {
  static Future<bool> _ensureLocationWhenInUse(BuildContext context) async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<GpsPermissionStatus> checkGpsAndPermissions() async {
    // GPS activat?
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) return GpsPermissionStatus.gpsOff;

    // Permisos?
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      return GpsPermissionStatus.permissionDenied;
    }

    return GpsPermissionStatus.ok;
  }

  // A permissions_service.dart

  static Future<bool> ensureBackgroundLocationWithDialog(
    BuildContext context,
  ) async {
    // 1. Comprovem si ja tenim el permís "Sempre" (Always)
    final status = await Permission.locationAlways.status;
    if (status.isGranted) return true;

    // 2. Si no el tenim, mostrem el TEU diàleg explicatiu (AppMessages)
    final continuar = await AppMessages.showPermissionExplanation(context);
    if (continuar != true) return false;

    // 3. Demanem el permís de sistema (Always)
    // Això és el que permet que el teu NativeGpsChannel continuï viu
    // quan l'usuari bloquegi la pantalla.
    final res = await Permission.locationAlways.request();

    if (res.isGranted) {
      await _ensureNotifications(context); // Ara fa servir el diàleg explicatiu
      await _ensureIgnoreBatteryOptimizations(context);
      return true;
    }

    return false;
  }

  // Evita que Android/fabricants matin el servei GPS en parades llargues amb pantalla apagada
  static Future<void> _ensureIgnoreBatteryOptimizations(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return;

    final alreadyIgnoring =
        await NativeGpsChannel.isIgnoringBatteryOptimizations();
    if (alreadyIgnoring) return;
    if (!context.mounted) return;

    final go = await AppMessages.showBatteryOptimizationDialog(context);
    if (go == true) {
      await NativeGpsChannel.requestIgnoreBatteryOptimizations();
    }
  }

  static Future<bool> _ensureGpsEnabled(BuildContext context) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) return true;

    // aquí pots mostrar un diàleg propi si vols
    return false;
  }

  static Future<bool> _ensureNotifications(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    // 1. Mostrem el TEU diàleg explicatiu abans de la petició del sistema
    await AppMessages.showNotificationPermissionDialog(context);

    // 2. Llançem la petició oficial del sistema
    final res = await Permission.notification.request();
    return res.isGranted;
  }

  /// Flux complet: while-in-use → GPS ON → background → notificacions
  static Future<bool> ensurePermissions(BuildContext context) async {
    // 1) While in use
    final whileInUse = await _ensureLocationWhenInUse(context);
    if (!whileInUse) return false;

    // 2) GPS ON
    final gpsOn = await _ensureGpsEnabled(context);
    if (!gpsOn) return false;

    // 3) Background — amb diàleg explicatiu propi ABANS de la petició del
    //    sistema, perquè l'usuari entengui per què cal el permís "sempre".
    final bg = await ensureBackgroundLocationWithDialog(context);
    if (!bg) return false;

    // 4) Notificacions (Android 13+)
    final notif = await _ensureNotifications(context);
    if (!notif) return false;

    return true;
  }

  static Future<bool> ensureGpsReady(BuildContext context) async {
    // 1) GPS activat?
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      final go = await AppMessages.showGpsDisabledDialog(context);
      if (go == true) Geolocator.openLocationSettings();
      return false;
    }

    // 2) Permisos while-in-use
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    // 3) Permís de background (Android): el seguiment ha de funcionar amb
    //    la pantalla apagada o l'app en segon pla, igual que la gravació.
    final bg = await ensureBackgroundLocationWithDialog(context);
    if (!bg) return false;

    // 4) Permís de notificacions (Android 13+)
    if (Platform.isAndroid) {
      final notifGranted = await _ensureNotifications(context);
      if (!notifGranted) return false;
    }

    return true;
  }

  // AFEGEIX AIXÒ AL FINAL DE LA TEVA CLASSE PermissionsService
  // Dins de ensureBasicLocation a PermissionsService.dart
  static Future<bool> ensureBasicLocation(BuildContext context) async {
    // Fem servir Geolocator per a la petició inicial
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
