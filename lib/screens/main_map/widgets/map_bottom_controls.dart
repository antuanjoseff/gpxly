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
import 'map_bottom_controls/recording_submenu.dart';
import 'map_bottom_controls/navigation_submenu.dart';

class MapBottomControls extends ConsumerStatefulWidget {
  final bool isChartCollapsed; // ja no s’utilitza per mostrar res aquí
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final void Function(String?) onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;
  final VoidCallback onToggleChart; // només es passa cap amunt

  const MapBottomControls({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onAddWaypoint,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
    required this.onToggleChart,
  });

  @override
  ConsumerState<MapBottomControls> createState() => _MapBottomControlsState();
}

class _MapBottomControlsState extends ConsumerState<MapBottomControls> {
  bool _showRecordingSubMenu = false;
  bool _showNavigationSubMenu = false;

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

    final bool isSubMenuOpen = _showRecordingSubMenu || _showNavigationSubMenu;

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
        // 🧭 SUBMENÚ DE NAVEGACIÓ
        if (_showNavigationSubMenu && hasTrack)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.subMenuHorizontalPadding,
            ),
            child: Container(
              margin: const EdgeInsets.only(
                bottom: AppDimensions.verticalSpacing,
              ),
              child: Center(
                child: NavigationSubMenu(
                  navState: navState,
                  hasTrack: hasTrack,
                  onAction: (bool val) {
                    setState(() => _showNavigationSubMenu = false);

                    if (!navState.isFollowing) {
                      widget.onHandleNavigationAction(
                        val ? "follow" : "clear_imported",
                      );
                    } else {
                      widget.onHandleNavigationAction(
                        val ? "toggle_pause" : "stop_follow",
                      );
                    }
                  },
                  onClose: () => setState(() => _showNavigationSubMenu = false),
                ),
              ),
            ),
          ),

        // ⏱️ SUBMENÚ DE GRAVACIÓ
        if (_showRecordingSubMenu)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.subMenuHorizontalPadding,
            ),
            child: Container(
              margin: const EdgeInsets.only(
                bottom: AppDimensions.verticalSpacing,
              ),
              child: Center(
                child: RecordingSubMenu(
                  state: recordingState,
                  onAction: (String action) {
                    setState(() => _showRecordingSubMenu = false);
                    widget.onOpenRecordingControl(action);
                  },
                  onClose: () => setState(() => _showRecordingSubMenu = false),
                ),
              ),
            ),
          ),

        // 🎛️ BARRA INFERIOR PRINCIPAL
        Padding(
          padding: EdgeInsets.only(bottom: widget.systemBottomPadding),
          child: MenuBar(
            isChartCollapsed: widget.isChartCollapsed,
            recordingState: recordingState,
            navState: navState,
            hasTrack: hasTrack,
            onRecordingTap: () {
              setState(() {
                _showRecordingSubMenu = !_showRecordingSubMenu;
                _showNavigationSubMenu = false;
              });
            },
            onNavigationTap: () {
              if (!hasTrack) {
                setState(() {
                  _showNavigationSubMenu = false;
                  _showRecordingSubMenu = false;
                });
                widget.onOpenNavigationControl(false);
              } else {
                setState(() {
                  _showNavigationSubMenu = !_showNavigationSubMenu;
                  _showRecordingSubMenu = false;
                });
              }
            },
            onToggleChart: widget.onToggleChart,
          ),
        ),
      ],
    );
  }
}
