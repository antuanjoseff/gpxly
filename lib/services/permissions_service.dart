import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/services/native_gps_channel.dart';

class PermissionsService {
  /// Flux correcte per Android 14 + Samsung OneUI 6
  static Future<bool> ensurePermissions(BuildContext context) async {
    // 1) Comprovar si el GPS està activat
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;

      final goToSettings = await _showConfirmDialog(
        context,
        title: "GPS desactivat",
        message: "Cal activar el GPS per poder enregistrar el track.",
      );

      if (goToSettings) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final enabledNow = await Geolocator.isLocationServiceEnabled();
      if (!enabledNow) return false;
    }

    print(">>> ensurePermissions CALLED");

    // 2) Comprovar permís actual
    LocationPermission permission = await Geolocator.checkPermission();
    print(">>> Initial permission = $permission");

    // 3) Demanar FINE/COARSE si cal
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print(">>> Requesting FINE permission...");
      permission = await Geolocator.requestPermission();
      print(">>> After requestPermission = $permission");

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return false;
      }
    }

    // Ara tenim com a mínim whileInUse
    print(">>> We have whileInUse, proceeding to BACKGROUND request");

    // 4) PRIMER intent: demanar BACKGROUND directament
    print(">>> Requesting BACKGROUND permission (native)...");
    await NativeGpsChannel.requestBackgroundPermission();

    // Donem temps al sistema
    await Future.delayed(const Duration(milliseconds: 600));

    // 5) Comprovar permís real
    bool realBg = await NativeGpsChannel.hasBackgroundPermission();
    print(">>> REAL ANDROID PERMISSION (after direct request) = $realBg");

    if (realBg) {
      print(">>> BACKGROUND granted directly");
      return true;
    }

    // 6) Si encara no tenim ALWAYS → ara sí obrim Configuració
    if (!context.mounted) return false;

    final goToSettings = await _showConfirmDialog(
      context,
      title: "Permís necessari",
      message:
          "Cal activar 'Permetre sempre' per enregistrar tracks amb la pantalla apagada.",
    );

    if (goToSettings) {
      print(">>> Opening app settings for ALWAYS...");
      await NativeGpsChannel.openAppLocationPermissions();

      // Samsung necessita temps
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 7) Tornem a demanar BACKGROUND després de Configuració
    print(">>> Requesting BACKGROUND permission again...");
    await NativeGpsChannel.requestBackgroundPermission();

    await Future.delayed(const Duration(milliseconds: 600));

    realBg = await NativeGpsChannel.hasBackgroundPermission();
    print(">>> REAL ANDROID PERMISSION (after settings) = $realBg");

    if (!realBg) {
      if (!context.mounted) return false;

      await _showDialog(
        context,
        title: "Permís insuficient",
        message:
            "Encara no tens 'Permetre sempre'. Sense això, el tracking no funcionarà en segon pla.",
      );
      return false;
    }

    return true;
  }

  /// Diàleg simple
  static Future<void> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("D'acord"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Diàleg amb confirmació
  static Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel·lar"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("Obrir configuració"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
