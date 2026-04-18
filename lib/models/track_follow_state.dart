import 'package:gpxly/notifiers/track_follow_notifier.dart';

class TrackFollowState {
  final bool isFollowing;
  final bool isOffTrack;
  final double distanceToTrack;
  final bool showOffTrackSnackbar;
  final bool showBackOnTrackSnackbar;
  final bool showEndOfTrackSnackbar; // 👈 NOU CAMP
  final bool showReverseTrackDialog;
  final FollowMode mode;

  const TrackFollowState({
    required this.isFollowing,
    required this.isOffTrack,
    required this.distanceToTrack,
    this.showOffTrackSnackbar = false,
    this.showBackOnTrackSnackbar = false,
    this.showEndOfTrackSnackbar = false, // 👈 VALOR PER DEFECTE
    this.mode = FollowMode.notFollowing,
    this.showReverseTrackDialog = false,
  });

  TrackFollowState copyWith({
    bool? isFollowing,
    bool? isOffTrack,
    double? distanceToTrack,
    bool? showOffTrackSnackbar,
    bool? showBackOnTrackSnackbar,
    bool? showEndOfTrackSnackbar,
    bool? showReverseTrackDialog, // 👈 FALTAVA AQUI
    FollowMode? mode,
  }) {
    return TrackFollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceToTrack: distanceToTrack ?? this.distanceToTrack,
      showOffTrackSnackbar: showOffTrackSnackbar ?? this.showOffTrackSnackbar,
      showBackOnTrackSnackbar:
          showBackOnTrackSnackbar ?? this.showBackOnTrackSnackbar,
      showEndOfTrackSnackbar:
          showEndOfTrackSnackbar ?? this.showEndOfTrackSnackbar,
      showReverseTrackDialog:
          showReverseTrackDialog ?? this.showReverseTrackDialog, // 👈 ARA SÍ
      mode: mode ?? this.mode,
    );
  }
}
