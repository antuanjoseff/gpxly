import 'package:flutter/material.dart' hide MenuBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/theme/app_dimensions.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'map_bottom_controls/layout_utils.dart';
import 'map_bottom_controls/elevation_panel.dart';
import 'map_bottom_controls/menu_bar.dart';
import 'map_bottom_controls/recording_submenu.dart';
import 'map_bottom_controls/navigation_submenu.dart';
import 'package:senda/widgets/recording_status_bar.dart'; // Per al TrackDurationTimer
import 'package:senda/l10n/app_localizations.dart'; // 🟢 Import indispensable per a les traduccions nates

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
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(
      context,
    )!; // 🟢 Inicialització del diccionari de l'App
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );
    final importedTrack = ref.watch(importedTrackProvider);
    final currentDuration = ref.watch(timerProvider);

    final recordingPoints = ref.watch(
      trackRecordingProvider.select((t) => t.points),
    );

    final layout = LayoutUtils.fromContext(
      context,
      isChartCollapsed: widget.isChartCollapsed,
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;

    final bool hasRecordingData =
        recordingState != RecordingState.idle && recordingPoints.isNotEmpty;

    final bool showChartData = hasTrack || (hasRecordingData && _showChart);

    final bool isSubMenuOpen = _showRecordingSubMenu || _showNavigationSubMenu;

    final bool isRecordingActive = recordingState == RecordingState.recording;
    final IconData statusIcon = isRecordingActive
        ? Icons.fiber_manual_record
        : Icons.pause_rounded;
    final Color statusColor = isRecordingActive
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ⏱️ 0. COMPTADOR FLOTANT ADAPTATIU AMB ICONA MULTI-ESTAT
          if (recordingState == RecordingState.recording ||
              recordingState == RecordingState.paused)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.mapSafetyPadding,
              ),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(45),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 14.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 8),
                      TrackDurationTimer(
                        state: recordingState,
                        duration: currentDuration,
                        color: statusColor,
                        fontSize: 16,
                        showIcon: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 📊 1. EL GRÀFIC D'ELEVACIONS
          // 📊 1. EL GRÀFIC D'ELEVACIONS
          if (showChartData && layout.isPanelActive)
            SizedBox(
              height: layout
                  .chartHeight, // Asegura que solo ocupe su espacio real inferior
              child: ElevationPanel(
                isVisible: layout.isPanelActive,
                isCollapsed: widget.isChartCollapsed,
                chartHeight: layout.chartHeight,
                isSubMenuOpen: isSubMenuOpen,
                onToggle: widget.onToggleChart,
              ),
            ),

          // 🧭 2. BAFARADA DE NAVEGACIÓ (Amb separació inferior forçada)
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
                ),
              ),
            ),
          // ⏱️ 3. BAFARADA DE GRAVACIÓ (Amb separació inferior forçada)
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
                    onAction: (String action) async {
                      setState(() {
                        _showRecordingSubMenu = false;
                      });

                      // 🟢 CONTROL DE RECUPERACIÓ DE GRAVACIÓ ANTERIOR AMB TRANSLATIONS
                      if (action == 'start') {
                        final prefs = await SharedPreferences.getInstance();
                        final hasOldData = prefs.containsKey('temp_track_data');

                        if (hasOldData && context.mounted) {
                          // 🟢 CRIDA MULTIIDIOMA CORREGIDA: Invoca el diàleg natiu reactiu de l'App
                          final bool? recuperar =
                              await AppMessages.showRecoverTrackDialog(context);

                          if (recuperar == true) {
                            // 1. CAS: L'USUARI RECUPERA LA RUTA ANTERIOR
                            setState(() {
                              _showChart = true;
                            });

                            await ref
                                .read(trackRecordingProvider.notifier)
                                .loadFromCache();

                            if (widget.isChartCollapsed) {
                              widget
                                  .onToggleChart(); // Obre el panell si estava tancat al pare
                            }

                            final trackRecuperat = ref.read(
                              trackRecordingProvider,
                            );
                            if (trackRecuperat.recordingState ==
                                RecordingState.recording) {
                              ref.read(timerProvider.notifier).start();
                            } else if (trackRecuperat.recordingState ==
                                RecordingState.paused) {
                              ref.read(timerProvider.notifier).pause();
                            }
                          } else if (recuperar == false) {
                            // 2. CAS: L'USUARI ELIMINA LA RUTA I EN COMENÇA UNA DE NOVA
                            setState(() {
                              _showChart = false;
                            });
                            await ref
                                .read(trackRecordingProvider.notifier)
                                .clearCache();
                            ref
                                .read(trackRecordingProvider.notifier)
                                .startRecording();

                            if (!widget.isChartCollapsed) {
                              widget.onToggleChart();
                            }
                          }
                        } else {
                          // 3. CAS: NO HI HA DADES VELLES (INICI NET STANDARD DE ZERO)
                          setState(() {
                            _showChart = false;
                          });
                          ref
                              .read(trackRecordingProvider.notifier)
                              .startRecording();

                          if (!widget.isChartCollapsed) {
                            widget.onToggleChart();
                          }
                        }
                      } else if (action == 'pause') {
                        ref
                            .read(trackRecordingProvider.notifier)
                            .pauseRecording();
                      } else if (action == 'resume') {
                        ref
                            .read(trackRecordingProvider.notifier)
                            .resumeRecording();
                      } else if (action == 'stop') {
                        final result =
                            await AppMessages.showStopRecordingDialog(context);
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
                ),
              ),
            ),

          // 🎛️ 4. BARRA DE MENÚ INFERIOR PRINCIPAL (Tanca la base)
          Padding(
            padding: EdgeInsets.only(bottom: widget.systemBottomPadding),
            child: MenuBar(
              isChartCollapsed: widget.isChartCollapsed,
              isPanelActive: layout.isPanelActive,
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
              onToggleChart: () {
                setState(() {
                  _showChart = widget.isChartCollapsed;
                });
                widget.onToggleChart();
              },
            ),
          ),
        ],
      ),
    );
  }
}
