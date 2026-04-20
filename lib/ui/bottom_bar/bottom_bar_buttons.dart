import 'package:flutter/material.dart';
import 'package:gpxly/models/track.dart';
import 'idle_buttons.dart';
import 'recording_buttons.dart';
import 'paused_buttons.dart';

class BottomBarButtons extends StatelessWidget {
  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final bool isFollowingTrack;

  // Callback per importar GPX
  final VoidCallback onImportTrack;

  // Nou: callback per seguir track
  final VoidCallback onFollowTrack;
  final bool hasImportedTrack;

  const BottomBarButtons({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onImportTrack,
    required this.onFollowTrack,
    required this.hasImportedTrack,
    required this.isFollowingTrack,
  });

  Widget _buildForState() {
    switch (state) {
      case RecordingState.idle:
        return IdleButtons(
          key: const ValueKey("idle"),
          onStart: onStart,
          onImportTrack: onImportTrack,
          onFollowTrack: onFollowTrack,
          hasImportedTrack: hasImportedTrack,
          isFollowingTrack: isFollowingTrack,
        );

      case RecordingState.recording:
        return RecordingButtons(
          key: const ValueKey("recording"),
          onPause: onPause,
          onImportTrack: onImportTrack,
          onFollowTrack: onFollowTrack,
        );

      case RecordingState.paused:
        return PausedButtons(
          key: const ValueKey("paused"),
          onResume: onResume,
          onStop: onStop,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildForState(),
    );
  }
}
