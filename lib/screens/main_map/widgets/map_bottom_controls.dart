import 'package:flutter/material.dart' hide MenuBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/ui/app_messages.dart';

import 'map_bottom_controls/layout_utils.dart';
import 'map_bottom_controls/elevation_panel.dart';
import 'map_bottom_controls/menu_bar.dart';
import 'map_bottom_controls/recording_submenu.dart';
import 'map_bottom_controls/navigation_submenu.dart';

class MapBottomControls extends ConsumerStatefulWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final VoidCallback onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;
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
  });

  @override
  ConsumerState<MapBottomControls> createState() => _MapBottomControlsState();
}

class _MapBottomControlsState extends ConsumerState<MapBottomControls> {
  bool _showRecordingSubMenu = false;
  bool _showNavigationSubMenu = false;

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );
    final importedTrack = ref.watch(importedTrackProvider);

    final layout = LayoutUtils.fromContext(
      context,
      isChartCollapsed: widget.isChartCollapsed,
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;

    final bool isSubMenuOpen = _showRecordingSubMenu || _showNavigationSubMenu;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. L'ElevationPanel flota al fons de l'Stack.
          // Com que és condicional o usa la seva alçada dinàmica, no empeny el menú.
          if (hasTrack && layout.isPanelActive)
            ElevationPanel(
              isVisible: layout.isPanelActive,
              isCollapsed: widget.isChartCollapsed,
              chartHeight: layout.chartHeight,
              isSubMenuOpen: isSubMenuOpen,
              onToggle: widget.onToggleChart,
            ),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Submenú de navegació (només si hi ha track)
              if (_showNavigationSubMenu && hasTrack) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: NavigationSubMenu(
                      navState: navState,
                      hasTrack: hasTrack,
                      onAction: (bool val) {
                        widget.onOpenNavigationControl(val);
                        setState(() {
                          _showNavigationSubMenu = false;
                        });
                      },
                      onClose: () =>
                          setState(() => _showNavigationSubMenu = false),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ⏱️ GESTIÓ EXCLUSIVA DE LA UX DE GRAVACIÓ
              if (_showRecordingSubMenu &&
                  recordingState != RecordingState.idle) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: RecordingSubMenu(
                      state: recordingState,
                      onAction: (String action) async {
                        setState(() {
                          _showRecordingSubMenu = false;
                        });

                        if (action == 'pause') {
                          ref
                              .read(trackRecordingProvider.notifier)
                              .pauseRecording();
                        } else if (action == 'resume') {
                          ref
                              .read(trackRecordingProvider.notifier)
                              .resumeRecording();
                        } else if (action == 'stop') {
                          // Obrim el diàleg final vertical definit a AppMessages
                          final result =
                              await AppMessages.showStopRecordingDialog(
                                context,
                              );

                          if (result == 'finish' || result == 'share') {
                            // 🚀 OBTENIM LA DURADA ACTUAL: Llegim el proveïdor del cronòmetre tal com fas al teu notifier
                            final currentDuration = ref.read(timerProvider);

                            // Aturem la gravació passant-li el positional argument de tipus Duration requerit
                            await ref
                                .read(trackRecordingProvider.notifier)
                                .stopRecording(currentDuration);

                            if (result == 'share' && context.mounted) {
                              AppMessages.showExportDialog(context);
                            }

                            ref.read(waypointsProvider.notifier).clear();
                          }
                        }
                      },
                      onClose: () =>
                          setState(() => _showRecordingSubMenu = false),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Menú principal inferior
              Padding(
                padding: EdgeInsets.only(bottom: widget.systemBottomPadding),
                child: MenuBar(
                  isChartCollapsed: widget.isChartCollapsed,
                  isPanelActive: layout.isPanelActive,
                  recordingState: recordingState,
                  navState: navState,
                  hasTrack: hasTrack,
                  onRecordingTap: () {
                    // IMPLEMENTACIÓ DEL NOU FLUX DE GRAVACIÓ:
                    if (recordingState == RecordingState.idle) {
                      // CAS INITIAL: No escollit res. El primer clic inicia la gravació de cop.
                      setState(() {
                        _showRecordingSubMenu = false;
                        _showNavigationSubMenu = false;
                      });
                      // Cridem directament la funció del pare per començar a gravar
                      widget.onOpenRecordingControl();
                    } else {
                      // CAS GRAVANT o PAUSAT: Commuta l'obertura del submenú amb les accions de control
                      setState(() {
                        _showRecordingSubMenu = !_showRecordingSubMenu;
                        _showNavigationSubMenu = false;
                      });
                    }
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
          ),
        ],
      ),
    );
  }
}
