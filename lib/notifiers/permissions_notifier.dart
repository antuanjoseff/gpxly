import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/gps_permission.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geo;

class PermissionsNotifier extends Notifier<GpsPermissionState> {
  StreamSubscription? _serviceSub;
  bool _pendingStartAfterGpsOn = false;

  @override
  GpsPermissionState build() {
    ref.onDispose(() {
      _serviceSub?.cancel();
    });

    _init();

    return const GpsPermissionState(
      hasPermission: false,
      serviceEnabled: false,
    );
  }

  Future<void> _init() async {
    // 1. Llegim l'estat inicial de forma atòmica
    await checkPermissions();
    await checkServiceStatus();

    // 2. Escoltem els canvis futurs del xip GPS
    _serviceSub = geo.Geolocator.getServiceStatusStream().listen((status) {
      // Millor usar l'enum ServiceStatus en lloc de .toString().contains(...)
      final bool enabled = status == geo.ServiceStatus.enabled;

      // Només actualitzem si l'estat realment ha canviat per estalviar redibuixats
      if (state.serviceEnabled != enabled) {
        state = state.copyWith(serviceEnabled: enabled);
        if (enabled && _pendingStartAfterGpsOn) {
          _pendingStartAfterGpsOn = false;
          state = state.copyWith(shouldResumeRecording: true);
        }
      }
    });
  }

  void setPendingAction(bool pending) => _pendingStartAfterGpsOn = pending;

  Future<void> checkPermissions() async {
    // Comprovem tots dos nivells
    final statusAlways = await perm.Permission.locationAlways.status;
    final statusInUse = await perm.Permission.location.status;

    // L'app "té permís" si qualsevol dels dos és positiu
    state = state.copyWith(
      hasPermission: statusAlways.isGranted || statusInUse.isGranted,
    );
  }

  Future<void> requestPermissions() async {
    // Quan demanes permís, el sistema sol anar per passos.
    // Millor demanar el genèric i després el 'always' si cal.
    final status = await perm.Permission.location.request();

    // Actualitzem l'estat basant-nos en el resultat immediat
    state = state.copyWith(hasPermission: status.isGranted);

    // Si vols forçar el 'always' després:
    if (status.isGranted) {
      final statusAlways = await perm.Permission.locationAlways.request();
      state = state.copyWith(hasPermission: statusAlways.isGranted);
    }
  }

  Future<void> checkServiceStatus() async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    state = state.copyWith(serviceEnabled: enabled);
  }

  void consumeSignal() {
    state = state.copyWith(shouldResumeRecording: false);
  }
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, GpsPermissionState>(
      PermissionsNotifier.new,
    );
