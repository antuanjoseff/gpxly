import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/gps_permission.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

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

  void setPendingFollowing(bool pending) async {
    state = state.copyWith(shouldResumeFollowing: pending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_follow', pending); // Persistència també aquí
  }

  void setPendingAction(bool pending) async {
    print("🔵 [NOTIFIER] Guardant pendent a disc: $pending");
    state = state.copyWith(shouldResumeRecording: pending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_rec', pending); // 💾 Guardem
  }

  void consumeSignal() async {
    print("🟢 [NOTIFIER] Consumint senyal (neteja disc)");
    state = state.copyWith(shouldResumeRecording: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_rec'); // 🗑️ Netegem
  }

  Future<void> checkServiceStatus() async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    final prefs = await SharedPreferences.getInstance();

    // Llegim els pendents del disc
    final bool pRec = prefs.getBool('pending_rec') ?? false;
    final bool pFol = prefs.getBool('pending_follow') ?? false;

    state = state.copyWith(
      serviceEnabled: enabled,
      shouldResumeRecording: pRec,
      shouldResumeFollowing: pFol,
    );

    // 🎯 LA CLAU: Si el GPS s'acaba d'activar i teníem pendent, forçem el "true"
    if (enabled && (pRec || pFol)) {
      print("🎯 [NOTIFIER] GPS detectat i acció pendent. Forçant senyal.");
      state = state.copyWith(
        shouldResumeRecording: pRec,
        shouldResumeFollowing: pFol,
      );
    }
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
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, GpsPermissionState>(
      PermissionsNotifier.new,
    );
