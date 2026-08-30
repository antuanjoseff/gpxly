// lib/models/navigation_state.dart

// Translladem l'enum aquí per netejar la dependència
enum FollowMode { notFollowing, initializing, onTrack, offTrack }

class NavigationState {
  final bool isFollowing;
  final bool isPaused;
  final bool isOffTrack;
  final double distanceToTrackLine;
  final FollowMode mode;

  // 🔔 Senyals (Flags) de notificacions per a la interfície d'usuari
  final bool showOffTrackSnackbar;
  final bool showBackOnTrackSnackbar;
  final bool showEndOfTrackSnackbar;
  final bool showWaypointSnackbar;
  final String? waypointSnackbarName;
  final bool showReverseTrackDialog;

  NavigationState({
    this.isFollowing = false,
    this.isPaused = false,
    this.isOffTrack = false,
    this.distanceToTrackLine = 0.0,
    this.mode = FollowMode.notFollowing,
    this.showOffTrackSnackbar = false,
    this.showBackOnTrackSnackbar = false,
    this.showEndOfTrackSnackbar = false,
    this.showWaypointSnackbar = false,
    this.waypointSnackbarName,
    this.showReverseTrackDialog = false,
  });

  NavigationState copyWith({
    bool? isFollowing,
    bool? isPaused,
    bool? isOffTrack,
    double? distanceToTrackLine,
    FollowMode? mode,
    bool? showOffTrackSnackbar,
    bool? showBackOnTrackSnackbar,
    bool? showEndOfTrackSnackbar,
    bool? showWaypointSnackbar,
    String? waypointSnackbarName,
    bool? showReverseTrackDialog,
  }) {
    return NavigationState(
      isFollowing: isFollowing ?? this.isFollowing,
      isPaused: isPaused ?? this.isPaused,
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceToTrackLine: distanceToTrackLine ?? this.distanceToTrackLine,
      mode: mode ?? this.mode,
      showOffTrackSnackbar: showOffTrackSnackbar ?? this.showOffTrackSnackbar,
      showBackOnTrackSnackbar:
          showBackOnTrackSnackbar ?? this.showBackOnTrackSnackbar,
      showEndOfTrackSnackbar:
          showEndOfTrackSnackbar ?? this.showEndOfTrackSnackbar,
      showWaypointSnackbar: showWaypointSnackbar ?? this.showWaypointSnackbar,
      waypointSnackbarName: waypointSnackbarName ?? this.waypointSnackbarName,
      showReverseTrackDialog:
          showReverseTrackDialog ?? this.showReverseTrackDialog,
    );
  }
}
