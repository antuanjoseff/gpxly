import 'package:flutter/material.dart';
import 'package:gpxly/models/track.dart';

class StartPauseResumeButton extends StatelessWidget {
  final Track track;
  final Future<void> Function() onStart;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;

  const StartPauseResumeButton({
    super.key,
    required this.track,
    required this.onStart,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = track.recording;
    final isPaused = track.paused;

    final color = !isRecording
        ? Colors.green
        : isPaused
        ? Colors.green
        : Colors.orange;

    final icon = !isRecording
        ? Icons.play_arrow
        : isPaused
        ? Icons.play_arrow
        : Icons.pause;

    return FloatingActionButton(
      backgroundColor: color,
      child: Icon(icon),
      onPressed: () async {
        if (!isRecording) return await onStart();
        if (!isPaused) return await onPause();
        return await onResume();
      },
    );
  }
}

class StopButton extends StatelessWidget {
  final Future<void> Function() onStop;

  const StopButton({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      child: const Icon(Icons.stop),
      onPressed: () async => await onStop(),
    );
  }
}
