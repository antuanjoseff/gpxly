import 'package:gpxly/notifiers/track_follow_notifier.dart';

class TrackFollowState {
  final bool isFollowing;
  final bool isOffTrack;
  final double distanceToTrack;
  final bool showOffTrackSnackbar;
  final bool showBackOnTrackSnackbar;

  final FollowMode mode; // 👈 NOU CAMP OBLIGATORI

  const TrackFollowState({
    required this.isFollowing,
    required this.isOffTrack,
    required this.distanceToTrack,
    this.showOffTrackSnackbar = false,
    this.showBackOnTrackSnackbar = false,
    this.mode = FollowMode.notFollowing, // 👈 VALOR PER DEFECTE
  });

  TrackFollowState copyWith({
    bool? isFollowing,
    bool? isOffTrack,
    double? distanceToTrack,
    bool? showOffTrackSnackbar,
    bool? showBackOnTrackSnackbar,
    FollowMode? mode,
  }) {
    return TrackFollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceToTrack: distanceToTrack ?? this.distanceToTrack,
      showOffTrackSnackbar: showOffTrackSnackbar ?? this.showOffTrackSnackbar,
      showBackOnTrackSnackbar:
          showBackOnTrackSnackbar ?? this.showBackOnTrackSnackbar,
      mode: mode ?? this.mode, // 👈 IMPORTANT
    );
  }
}
