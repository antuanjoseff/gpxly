class GpsPermissionState {
  final bool hasPermission;
  final bool serviceEnabled;

  const GpsPermissionState({
    required this.hasPermission,
    required this.serviceEnabled,
  });

  GpsPermissionState copyWith({bool? hasPermission, bool? serviceEnabled}) {
    return GpsPermissionState(
      hasPermission: hasPermission ?? this.hasPermission,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
    );
  }
}
