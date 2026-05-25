class GpsPermissionState {
  final bool hasPermission;
  final bool serviceEnabled;
  final bool shouldResumeRecording;
  final bool shouldResumeFollowing;

  const GpsPermissionState({
    required this.hasPermission,
    required this.serviceEnabled,
    this.shouldResumeRecording = false,
    this.shouldResumeFollowing = false,
  });

  GpsPermissionState copyWith({
    bool? hasPermission,
    bool? serviceEnabled,
    bool? shouldResumeRecording,
    bool? shouldResumeFollowing,
  }) {
    return GpsPermissionState(
      hasPermission: hasPermission ?? this.hasPermission,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      shouldResumeRecording:
          shouldResumeRecording ?? this.shouldResumeRecording,
      shouldResumeFollowing:
          shouldResumeFollowing ?? this.shouldResumeFollowing,
    );
  }
}
