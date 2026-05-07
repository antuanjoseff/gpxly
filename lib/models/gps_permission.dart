class GpsPermissionState {
  final bool hasPermission;
  final bool serviceEnabled;
  final bool shouldResumeRecording;

  const GpsPermissionState({
    required this.hasPermission,
    required this.serviceEnabled,
    this.shouldResumeRecording = false,
  });

  GpsPermissionState copyWith({
    bool? hasPermission,
    bool? serviceEnabled,
    bool? shouldResumeRecording,
  }) {
    return GpsPermissionState(
      hasPermission: hasPermission ?? this.hasPermission,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      shouldResumeRecording:
          shouldResumeRecording ?? this.shouldResumeRecording,
    );
  }
}
