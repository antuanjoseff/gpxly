import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/screens/stats/stats_screen.dart';
import 'package:senda/widgets/compass_widget.dart';
import 'package:senda/widgets/recording_status_bar.dart';

class MapTopControls extends ConsumerWidget {
  final MapLibreMapController? mapController;
  final bool smartCenterEnabled;
  final VoidCallback onCenterOnUser;
  final VoidCallback onAddWaypoint;
  final Widget Function({required IconData icon, required VoidCallback onTap})
  buildSquareButton;

  const MapTopControls({
    super.key,
    required this.mapController,
    required this.smartCenterEnabled,
    required this.onCenterOnUser,
    required this.onAddWaypoint,
    required this.buildSquareButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: RecordingStatusBar(
            state: ref.watch(
              trackRecordingProvider.select((t) => t.recordingState),
            ),
            duration: ref.watch(timerProvider),
          ),
        ),
        Positioned(
          top: 10,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CompassScalePanel(
                onTapCompass: () =>
                    mapController?.animateCamera(CameraUpdate.bearingTo(0)),
              ),
              const SizedBox(height: 8),
              buildSquareButton(
                icon: Icons.bar_chart,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackStatsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (ref.watch(trackRecordingProvider).recordingState ==
                  RecordingState.recording) ...[
                buildSquareButton(
                  icon: Icons.add_location_alt_outlined,
                  onTap: onAddWaypoint,
                ),
                const SizedBox(height: 8),
              ],
              if (!smartCenterEnabled)
                buildSquareButton(icon: Icons.gps_fixed, onTap: onCenterOnUser),
            ],
          ),
        ),
      ],
    );
  }
}
