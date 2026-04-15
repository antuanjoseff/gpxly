class TrackFollowState {
  final bool isFollowing;
  final bool isOffTrack;
  final double distanceToTrack;

  const TrackFollowState({
    required this.isFollowing,
    required this.isOffTrack,
    required this.distanceToTrack,
  });

  TrackFollowState copyWith({
    bool? isFollowing,
    bool? isOffTrack,
    double? distanceToTrack,
  }) {
    return TrackFollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceToTrack: distanceToTrack ?? this.distanceToTrack,
    );
  }
}
