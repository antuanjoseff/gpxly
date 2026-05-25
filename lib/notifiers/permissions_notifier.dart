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

  void setPendingAction(bool pending) {
    state = state.copyWith(shouldResumeRecording: pending);
  }

  void setPendingFollowing(bool pending) {
    state = state.copyWith(shouldResumeFollowing: pending);
  }

  Future<void> _init() async {
    await checkPermissions();
    await checkServiceStatus();

    _serviceSub = geo.Geolocator.getServiceStatusStream().listen((status) {
      final bool enabled = status == geo.ServiceStatus.enabled;

      if (state.serviceEnabled != enabled) {
        // Si el GPS s'encén, mirem si hi havia alguna cosa pendent a l'estat
        state = state.copyWith(
          serviceEnabled: enabled,
          // Si teníem la "intenció" guardada, la mantenim perquè el MapScreen la llegeixi
        );
      }
    });
  }

  void consumeFollowSignal() {
    state = state.copyWith(shouldResumeFollowing: false);
  }

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
