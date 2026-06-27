// lib/screens/main_map/widgets/map_stack_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/helpers/elevation_magnet_helper.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/segment_stats_notifier.dart';
import 'package:senda/screens/elevations/widgets/segment_stats_widget.dart';
import 'package:senda/screens/main_map/widgets/map_bottom_controls/elevation_panel.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/theme/app_dimensions.dart';

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
    final stats = ref.watch(segmentStatsProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0.0, // Clavat al fons de la pantalla
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ocupa només l'espai necessari
        children: [
          // 📊 EL GRÀFIC D'ELEVACIONS
          ElevationPanel(
            isCollapsed: isChartCollapsed,
            onCollapseChanged: (collapsed) {
              final newValue = !isChartCollapsed;
              onCollapseChanged(newValue);
              _notifySelectionCollapse(ref, newValue);
            },
          ),

          // 🟩 LA BARRA NEGRA D'ESTADÍSTIQUES (A sota, tocant-se directament)
          SegmentStatsWidget(
            distanceMeters: stats.distanceMeters,
            timeElapsedStr: stats.timeElapsedStr,
            avgSpeedStr: stats.avgSpeedStr,
            ascentMeters: stats.ascentMeters,
            descentMeters: stats.descentMeters,
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

/// 🚀 WIDGET MODULAR 2: EL BOTÓN MAESTRO DE LAS TIJERAS (CON FILTRO DE COORDENADAS)
class MapScissorsButtons extends ConsumerWidget {
  final bool isChartCollapsed;
  final MapLibreMapController? mapController;

  const MapScissorsButtons({
    super.key,
    required this.isChartCollapsed,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ Obtenim l'estat dels tracks i la selecció de Riverpod
    final sel = ref.watch(elevationSelectionProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final recordingTrack = ref.watch(trackRecordingProvider);

    // 2️⃣ Extraiem el nombre de coordenades de cada track de forma segura
    final int importedCoordsCount = importedTrack?.coordinates.length ?? 0;
    final int recordingCoordsCount = recordingTrack.coordinates.length ?? 0;

    // 3️⃣ Validem si algun dels dos tracks té prou coordenades (Mínim N)
    final bool hasEnoughImported =
        importedCoordsCount >= AppDimensions.minCoordinatesForSelection;
    final bool hasEnoughRecording =
        recordingCoordsCount >= AppDimensions.minCoordinatesForSelection;

    // 🛡️ REGLA DE NEGOCI: Si no hi ha cap ruta vàlida amb més de N punts, amaguem completament el botó
    if (!hasEnoughImported && !hasEnoughRecording) {
      return const SizedBox.shrink();
    }

    // A partir d'aquí la lògica de renderitzat i mides es manté idèntica
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double chartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    final bool hasImportedTrack = importedTrack != null;
    final bool isChartVisibleReal = !isChartCollapsed && hasImportedTrack;

    final double bottomOffset = isChartVisibleReal ? 60.0 + chartHeight : 60.0;

    final bool isToolActive = sel.mapToolState != MapSelectionToolState.off;
    final bool isSelected = sel.mapToolState == MapSelectionToolState.selected;

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

    return Stack(
      children: [
        // 🔵 BOTÓ PRINCIPAL (TISORES / CANCEL·LAR)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          right: 16,
          bottom: bottomOffset,
          child: FloatingActionButton(
            heroTag: "btn_tisores_toggle_maestro",
            backgroundColor: isToolActive
                ? AppColors.logoGreen
                : AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              if (isToolActive) {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .deactivateMapSelectionTool();
              } else {
                _handleInitialActivation(ref);
              }
            },
            child: iconTijerasPersonalizado,
          ),
        ),

        // 🔄 BOTÓ RESET TRAM (Meteix tamany i enganxat al costat)
        if (isSelected)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            right: 80,
            bottom: bottomOffset,
            child: FloatingActionButton(
              heroTag: "btn_reset_tram",
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              onPressed: () {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .resetMapSelection();
              },
              child: const Icon(Icons.refresh, size: 26),
            ),
          ),
      ],
    );
  }

  void _handleInitialActivation(WidgetRef ref) {
    ref.read(elevationSelectionProvider.notifier).activateMapSelectionTool();

    if (mapController != null) {
      ElevationMagnetHelper.recalcularIActualitzar(
        ref: ref,
        mapController: mapController!,
      );
    }
  }
}
