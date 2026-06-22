// lib/widgets/recording_status_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/location_notifier.dart';

// lib/widgets/recording_status_bar.dart

class TrackDurationTimer extends StatelessWidget {
  final RecordingState state;
  final Duration duration;
  final Color color;
  final double fontSize; // 🚀 Afegit per fer-lo més flexible
  final bool showIcon; // 🚀 Afegit per poder amagar-la

  const TrackDurationTimer({
    super.key,
    required this.state,
    required this.duration,
    required this.color,
    this.fontSize = 16, // Valor per defecte original
    this.showIcon = true, // Valor per defecte original
  });

  @override
  Widget build(BuildContext context) {
    Widget? stateIcon;
    if (showIcon) {
      if (state == RecordingState.recording) {
        stateIcon = Icon(Icons.play_arrow_rounded, color: color, size: 18);
      } else if (state == RecordingState.paused) {
        stateIcon = Icon(Icons.pause_rounded, color: color, size: 18);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (stateIcon != null) ...[stateIcon, const SizedBox(width: 6)],
        Text(
          duration.toString().split('.').first.padLeft(8, "0"),
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: fontSize, // 🚀 Mida de font dinàmica
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class LocationAltitude extends ConsumerWidget {
  final Color color; // 🚀 Afegit

  const LocationAltitude({super.key, required this.color}); // 🚀 Modificat

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(locationProvider);
    final double? altitude = userPos?.altitude;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.filter_hdr_rounded, color: color, size: 20), // 🚀 Aplicat
        const SizedBox(width: 6),
        Text(
          altitude != null ? "${altitude.toStringAsFixed(0)}m" : "---m",
          style: TextStyle(
            color: color, // 🚀 Aplicat
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
