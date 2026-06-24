import 'package:flutter/material.dart' hide MenuBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/theme/app_dimensions.dart';
import 'package:senda/l10n/app_localizations.dart';

import 'map_bottom_controls/menu_bar.dart';

class MapBottomControls extends ConsumerStatefulWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final void Function(String?) onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;
  final VoidCallback onToggleRecordingSubmenu;
  final VoidCallback onToggleNavigationSubmenu;
  final VoidCallback onToggleChart;

  const MapBottomControls({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onAddWaypoint,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
    required this.onToggleChart,
    required this.onToggleRecordingSubmenu,
    required this.onToggleNavigationSubmenu,
  });

  @override
  ConsumerState<MapBottomControls> createState() => _MapBottomControlsState();
}

class _MapBottomControlsState extends ConsumerState<MapBottomControls> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );
    final importedTrack = ref.watch(importedTrackProvider);
    final currentDuration = ref.watch(timerProvider);

    final recordingPoints = ref.watch(
      trackRecordingProvider.select((t) => t.points),
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;

    final bool hasRecordingData =
        recordingState != RecordingState.idle && recordingPoints.isNotEmpty;

    final bool isRecordingActive = recordingState == RecordingState.recording;
    final IconData statusIcon = isRecordingActive
        ? Icons.fiber_manual_record
        : Icons.pause_rounded;
    final Color statusColor = isRecordingActive
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: widget.systemBottomPadding),
          child: MenuBar(
            isChartCollapsed: widget.isChartCollapsed,
            recordingState: recordingState,
            navState: navState,
            hasTrack: hasTrack,
            onRecordingTap: widget.onToggleRecordingSubmenu,
            onNavigationTap: widget.onToggleNavigationSubmenu,
            onToggleChart: widget.onToggleChart,
          ),
        ),
      ],
    );
  }
}
