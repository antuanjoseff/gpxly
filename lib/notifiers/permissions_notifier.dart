import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/gps_permission.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geo;

class PermissionsNotifier extends Notifier<GpsPermissionState> {
  StreamSubscription? _serviceSub;

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
    await checkPermissions();
    await checkServiceStatus();

    _serviceSub = geo.Geolocator.getServiceStatusStream().listen((status) {
      // status és un enum intern no públic → només podem usar toString()
      final enabled = status.toString().contains('enabled');
      state = state.copyWith(serviceEnabled: enabled);
    });
  }

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
