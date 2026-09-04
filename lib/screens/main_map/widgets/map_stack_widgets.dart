// lib/screens/main_map/widgets/map_stack_widgets.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/notifiers/helpers/elevation_magnet_helper.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/segment_stats_notifier.dart';
import 'package:strack_rec/screens/elevations/widgets/segment_stats_widget.dart';
import 'package:strack_rec/screens/main_map/widgets/map_bottom_controls/elevation_panel.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/theme/app_dimensions.dart';

/// 🚀 WIDGET MODULAR 1: EL CONTROL DE GRÀFICS I ESTADÍSTIQUES FIXES
class MapElevationHud extends ConsumerWidget {
  final bool isChartCollapsed;
  final Function(bool) onCollapseChanged;

  const MapElevationHud({
    super.key,
    required this.isChartCollapsed,
    required this.onCollapseChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realTrack = ref.watch(trackRecordingProvider);
    final isRecording = realTrack.recordingState == RecordingState.recording;

    // 🚀 Escoltem el segment_stats_notifier (que ja calcula Tot o Tram segons convingui)
    final stats = ref.watch(segmentStatsProvider);

    // 🚀 Mirem si hi ha una selecció de tram activa real a l'app
    final selection = ref.watch(elevationSelectionProvider);
    final bool hiHaTramActiu =
        (selection.mode == SelectionMode.range) ||
        (selection.mapToolState == MapSelectionToolState.selected);

    double finalDistanceMeters = 0.0;
    double finalAscent = 0.0;
    double finalDescent = 0.0;
    String finalTimeStr = "";
    String finalAvgSpeedStr = "";

    // 🔄 LA REGLA DE NEGOCI CORREGIDA:
    if (isRecording) {
      // 1️⃣ SI S'ESTÀ GRAVANT: Mostrem sempre les dades totals en viu de la gravació
      finalDistanceMeters = realTrack.stats.distance;
      finalAscent = realTrack.stats.ascent.roundToDouble();
      finalDescent = realTrack.stats.descent.roundToDouble();

      final movingDuration =
          realTrack.stats.duration - realTrack.stats.stoppedDuration;
      final hours = movingDuration.inHours;
      final minutes = movingDuration.inMinutes.remainder(60);

      if (hours > 0) {
        finalTimeStr = "${hours}h ${minutes.toString().padLeft(2, '0')}m";
      } else {
        finalTimeStr =
            "${minutes}m ${movingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}s";
      }

      finalAvgSpeedStr =
          "${realTrack.stats.averageSpeed.toStringAsFixed(1)} km/h";
    } else if (hiHaTramActiu) {
      // 2️⃣ SI HI HA UN TRAM SELECCIONAT: Mostrem les dades filtrades del segment
      finalDistanceMeters = stats.distanceMeters;
      finalAscent = stats.ascentMeters;
      finalDescent = stats.descentMeters;
      finalTimeStr = stats.timeElapsedStr;
      finalAvgSpeedStr = stats.avgSpeedStr;
    } else {
      // 3️⃣ SI NO HI HA TRAM NI GRAVACIÓ: Mostrem el total del track general (importat/restant)
      finalDistanceMeters = stats.distanceMeters;
      finalAscent = stats.ascentMeters;
      finalDescent = stats.descentMeters;
      finalTimeStr = stats.timeElapsedStr;
      finalAvgSpeedStr = stats.avgSpeedStr;
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0.0, // Clavat al fons de la pantalla
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 📊 EL GRÀFIC D'ELEVACIONS (Que rebrà el flux de dades net sense parpelleigs)
          ElevationPanel(
            isCollapsed: isChartCollapsed,
            onCollapseChanged: (collapsed) {
              final newValue = !isChartCollapsed;
              onCollapseChanged(newValue);
              _notifySelectionCollapse(ref, newValue);
            },
          ),

          SegmentStatsWidget(
            distanceMeters: finalDistanceMeters,
            timeElapsedStr: finalTimeStr,
            avgSpeedStr: finalAvgSpeedStr,
            ascentMeters: finalAscent,
            descentMeters: finalDescent,
            onTap: () {
              final newValue = !isChartCollapsed;
              onCollapseChanged(newValue);
              _notifySelectionCollapse(ref, newValue);
            },
          ),
        ],
      ),
    );
  }

  void _notifySelectionCollapse(WidgetRef ref, bool collapsed) {
    if (collapsed) {
      ref.read(elevationSelectionProvider.notifier).userCollapsedChart();
    } else {
      ref.read(elevationSelectionProvider.notifier).userOpenedChart();
    }
  }
}

class MapScissorsButtons extends ConsumerWidget {
  final bool isChartCollapsed;
  final MapLibreMapController? mapController;
  final Function(bool)
  onCollapseChanged; // 🟢 CALLBACK REQUERIT PER AL GEST INICIAL

  const MapScissorsButtons({
    super.key,
    required this.isChartCollapsed,
    required this.onCollapseChanged,
    this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(elevationSelectionProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final recordingTrack = ref.watch(trackRecordingProvider);

    final int importedCoordsCount = importedTrack?.coordinates.length ?? 0;
    final int recordingCoordsCount = recordingTrack.coordinates.length ?? 0;

    final bool hasEnoughImported =
        importedCoordsCount >= AppDimensions.minCoordinatesForSelection;
    final bool hasEnoughRecording =
        recordingCoordsCount >= AppDimensions.minCoordinatesForSelection;

    if (!hasEnoughImported && !hasEnoughRecording) {
      return const SizedBox.shrink();
    }

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double chartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    final bool hasImportedTrack = importedTrack != null;
    final bool hasRecordingTrack = recordingTrack.coordinates.isNotEmpty;

    // 🔍 Mirem si l'eina de les tisores està oberta en qualsevol estat
    final bool isToolActive = sel.mapToolState != MapSelectionToolState.off;

    // 🟢 SINCRONIA D'ALÇADA LLIURE: Traiem qualsevol bloqueig fix de fons.
    // Tot el grup horitzontal de botons es mourà de manera coordinada segons com estigui el gràfic realment a la pantalla.
    final bool isChartVisibleReal =
        !isChartCollapsed && (hasImportedTrack || hasRecordingTrack);
    final double bottomOffset = isChartVisibleReal ? 60.0 + chartHeight : 60.0;

    final Widget iconTijerasPersonalizado = SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Positioned(
            left: -1,
            bottom: 7,
            child: Icon(Icons.location_on, size: 21, color: Colors.white),
          ),
          const Positioned(
            right: -1,
            bottom: 7,
            child: Icon(Icons.location_on, size: 21, color: Colors.white),
          ),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      right: 16,
      bottom: bottomOffset,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Alineació central horitzontal perfecta
        children: [
          //  BOTÓ PRINCIPAL MESTRE (TISORES / CANCEL·LAR / RESET)
          SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              heroTag: "btn_tisores_toggle_maestro",
              backgroundColor: isToolActive
                  ? AppColors.logoGreen
                  : AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                if (isToolActive) {
                  // La X sempre tanca del tot l'eina: netegem retícula, cercles i tram en un sol clic.
                  ref
                      .read(elevationSelectionProvider.notifier)
                      .deactivateMapSelectionTool();
                } else {
                  ref
                      .read(elevationSelectionProvider.notifier)
                      .activateReticleMode();

                  if (mapController != null) {
                    ElevationMagnetHelper.recalcularIActualitzar(
                      ref: ref,
                      mapController: mapController!,
                    );
                  }

                  // 🚀 GEST AUTOMÀTIC: Únicament en el moment exacte de prémer les tisores de zero,
                  // col·lapsem el gràfic per obrir espai de treball lliure inicial al mapa.
                  onCollapseChanged(true);
                }
              },
              child: isToolActive
                  ? const Icon(Icons.close, size: 28)
                  : iconTijerasPersonalizado,
            ),
          ),
        ],
      ),
    );
  }
}
