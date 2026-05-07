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
          // Cridem al RecordingHandler automàticament des d'aquí o notifiquem a la UI
        }
      }
    });
  }

  void setPendingAction(bool pending) => _pendingStartAfterGpsOn = pending;

  Future<void> checkPermissions() async {
    final status = await perm.Permission.location.status;
    state = state.copyWith(hasPermission: status.isGranted);
  }

  Future<void> requestPermissions() async {
    final status = await perm.Permission.location.request();
    state = state.copyWith(hasPermission: status.isGranted);
  }

  Future<void> checkServiceStatus() async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    state = state.copyWith(serviceEnabled: enabled);
  }
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, GpsPermissionState>(
      PermissionsNotifier.new,
    );
