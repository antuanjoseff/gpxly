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
    final currentDuration = ref.watch(timerProvider);

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
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip
            .none, // Permet que els submenús flotin cap amunt de forma lliure
        children: [
          // 📊 1. EL BLOC DEL GRÀFIC I EL MENÚ PRINCIPAL (Sempre enganxats)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El gràfic d'elevacions amb el Listener de baix nivell per al drag
              if (hasTrack && layout.isPanelActive)
                Listener(
                  behavior: HitTestBehavior.opaque,
                  child: ElevationPanel(
                    isVisible: layout.isPanelActive,
                    isCollapsed: widget.isChartCollapsed,
                    chartHeight: layout.chartHeight,
                    isSubMenuOpen: isSubMenuOpen,
                    onToggle: widget.onToggleChart,
                  ),
                ),

              // 🚀 ELIMINAT EL SIZEDBOX: Ara el gràfic i el MenuBar es toquen directament al píxel

              // Barra de menú inferior principal (Sempre tanca la base)
              Padding(
                padding: EdgeInsets.only(bottom: widget.systemBottomPadding),
                child: MenuBar(
                  isChartCollapsed: widget.isChartCollapsed,
                  isPanelActive: layout.isPanelActive,
                  recordingState: recordingState,
                  navState: navState,
                  hasTrack: hasTrack,
                  onRecordingTap: () {
                    if (recordingState == RecordingState.idle) {
                      setState(() {
                        _showRecordingSubMenu = false;
                        _showNavigationSubMenu = false;
                      });
                      ref
                          .read(trackRecordingProvider.notifier)
                          .startRecording();
                    } else {
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

          // 🧭 2. LES BAFARADES FLOTANTS (Floten de forma independent sobre la base)
          // Les posicionem desplaçades cap amunt exactament l'alçada del MenuBar (72px) per no trepitjar res
          if (isSubMenuOpen)
            Positioned(
              bottom:
                  72 +
                  widget.systemBottomPadding +
                  12, // Alçada de la barra + padding de seguretat + aire
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showNavigationSubMenu && hasTrack)
                    NavigationSubMenu(
                      navState: navState,
                      hasTrack: hasTrack,
                      onAction: (bool val) {
                        setState(() {
                          _showNavigationSubMenu = false;
                        });
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
                      onClose: () =>
                          setState(() => _showNavigationSubMenu = false),
                    ),

                  if (_showRecordingSubMenu &&
                      recordingState != RecordingState.idle)
                    RecordingSubMenu(
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
                          final result =
                              await AppMessages.showStopRecordingDialog(
                                context,
                              );
                          if (result == 'finish' || result == 'share') {
                            final currentDuration = ref.read(timerProvider);
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
