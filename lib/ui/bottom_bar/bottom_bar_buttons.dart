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

  // Callback per importar GPX
  final VoidCallback onImportTrack;

  // Nou: callback per seguir track
  final VoidCallback onFollowTrack;

  const BottomBarButtons({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onImportTrack,
    required this.onFollowTrack,
  });

  Widget _buildForState() {
    switch (state) {
      case RecordingState.idle:
        return IdleButtons(
          key: const ValueKey("idle"),
          onStart: onStart,
          onImportTrack: onImportTrack,
        );

      case RecordingState.recording:
        return RecordingButtons(
          key: const ValueKey("recording"),
          onPause: onPause,
          onImportTrack: onImportTrack,
          onFollowTrack: onFollowTrack, // 👈 AFEGIT
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
