// lib/screens/main_map/widgets/map_stack_widgets.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
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
    // 1️⃣ Escuchamos los estados de grabación e importación de forma directa
    final realTrack = ref.watch(trackRecordingProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final isRecording = realTrack.recordingState == RecordingState.recording;

    // Si no hay grabación activa, recurrimos al cálculo del provider general de la ruta
    final stats = ref.watch(segmentStatsProvider);

    // 2️⃣ VARIABLES DE CONTROL PER A LA BARRA NEGRA (Tipus double unificats sense errors)
    // 2️⃣ VARIABLES DE CONTROL PER A LA BARRA NEGRA (Tipus double unificats sense errors)
    double finalDistanceMeters = 0.0;
    double finalAscent = 0.0;
    double finalDescent = 0.0;

    // Variables locals per calcular el temps i velocitat reals de gravació a mà
    String finalTimeStr = stats.timeElapsedStr;
    String finalAvgSpeedStr = stats.avgSpeedStr;

    if (isRecording) {
      // Quilometratge real basat en l'últim punt del GPS gravat
      finalDistanceMeters = realTrack.distances.isNotEmpty
          ? realTrack.distances.last * 1000.0
          : 0.0;

      // Càlcul de desnivells reals de la gravació
      double ascent = 0.0;
      double descent = 0.0;
      for (int i = 1; i < realTrack.altitudes.length; i++) {
        final diff = realTrack.altitudes[i] - realTrack.altitudes[i - 1];
        if (diff > 0) ascent += diff;
        if (diff < 0) descent += diff.abs();
      }
      finalAscent = ascent.roundToDouble();
      finalDescent = descent.roundToDouble();

      // 🟢 CÀLCUL MANUAL DEL TEMPS REAL DE GRAVACIÓ:
      // Comparem el primer timestamp gravat amb l'últim per saber els minuts de veritat
      if (realTrack.timestamps.length > 1) {
        final duration = realTrack.timestamps.last.difference(
          realTrack.timestamps.first,
        );
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);

        if (hours > 0) {
          finalTimeStr = "${hours}h ${minutes.toString().padLeft(2, '0')}m";
        } else {
          finalTimeStr =
              "${minutes}m ${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}s";
        }

        // 🟢 CÀLCUL MANUAL DE LA VELOCITAT MITJANA REAL:
        // Velocitat = (Metres / 1000) / (Segons / 3600) -> km/h
        if (duration.inSeconds > 0) {
          final double km = finalDistanceMeters / 1000.0;
          final double h = duration.inSeconds / 3600.0;
          final double avgSpeed = km / h;
          finalAvgSpeedStr = "${avgSpeed.toStringAsFixed(1)} km/h";
        } else {
          finalAvgSpeedStr = "0.0 km/h";
        }
      } else {
        finalTimeStr = "0m 00s";
        finalAvgSpeedStr = "0.0 km/h";
      }
    } else {
      finalDistanceMeters = stats.distanceMeters;
      finalAscent = stats.ascentMeters;
      finalDescent = stats.descentMeters;
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

          // 🟩 LA BARRA NEGRA D'ESTADÍSTIQUES (Sincronitzada de manera local sense race conditions)
          // 🟩 LA BARRA NEGRA D'ESTADÍSTIQUES (Sincronitzada i neta d'errors de mètodes)
          // 🟩 LA BARRA NEGRA D'ESTADÍSTIQUES (Totalment lliure d'interferències de temps històrics)
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
    final bool hasRecordingTrack = recordingTrack
        .coordinates
        .isNotEmpty; // 🚀 Nova comprovació per al gravat

    final bool isChartVisibleReal =
        !isChartCollapsed && (hasImportedTrack || hasRecordingTrack);

    final double bottomOffset = isChartVisibleReal ? 60.0 + chartHeight : 60.0;

    final bool isToolActive = sel.mapToolState != MapSelectionToolState.off;

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
