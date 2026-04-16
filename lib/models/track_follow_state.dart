class TrackFollowState {
  final bool isFollowing;
  final bool isOffTrack;
  final double distanceToTrack;
  final bool showOffTrackSnackbar;
  final bool showBackOnTrackSnackbar;

  const TrackFollowState({
    required this.isFollowing,
    required this.isOffTrack,
    required this.distanceToTrack,
    this.showOffTrackSnackbar = false,
    this.showBackOnTrackSnackbar = false,
  });

  TrackFollowState copyWith({
    bool? isFollowing,
    bool? isOffTrack,
    double? distanceToTrack,
    bool? showOffTrackSnackbar,
    bool? showBackOnTrackSnackbar,
  }) {
    return TrackFollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceToTrack: distanceToTrack ?? this.distanceToTrack,
      showOffTrackSnackbar: showOffTrackSnackbar ?? this.showOffTrackSnackbar,
      showBackOnTrackSnackbar:
          showBackOnTrackSnackbar ?? this.showBackOnTrackSnackbar,
    );
  }
}
