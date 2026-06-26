// lib/screens/main_map/widgets/map_stack_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/helpers/elevation_magnet_helper.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
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

/// 🚀 WIDGET MODULAR 2: EL BOTÓN MAESTRO DE LAS TIJERAS (ESTILO TOGGLE)
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
    final sel = ref.watch(elevationSelectionProvider);

    // Calculamos la altura para no pisar el grafico de elevacion
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double chartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    // 🚀 BLINDATGE VISUAL: Si no hi ha track importat, el gràfic no existeix a la pantalla
    final bool hasImportedTrack = ref.watch(importedTrackProvider) != null;

    // El botó només pujarà si el gràfic NO està col·lapsat I realment hi ha un track que el mostri
    final bool isChartVisibleReal = !isChartCollapsed && hasImportedTrack;

    final double bottomOffset = isChartVisibleReal ? 60.0 + chartHeight : 60.0;

    final bool isToolActive = sel.mapToolState != MapSelectionToolState.off;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      right: 16,
      bottom: bottomOffset,
      child: FloatingActionButton(
        heroTag: "btn_tisores_toggle_maestro",
        // 🎨 Si está activo se vuelve gris oscuro/rojo suave para indicar "Cerrar"
        backgroundColor: isToolActive
            ? Colors.grey.shade800
            : AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          if (isToolActive) {
            // ❌ REGLA NUEVA: Si está activa, un clic aquí cancela y apaga todo
            ref
                .read(elevationSelectionProvider.notifier)
                .deactivateMapSelectionTool();
          } else {
            // 🟢 Si está apagada, enciende la herramienta en el mapa
            _handleInitialActivation(ref);
          }
        },
        child: isToolActive
            ? const Icon(
                Icons.close,
                size: 26,
              ) // ❌ Icono de cancelar si está encendido
            : SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  children: [
                    // Tu trazado blanco del botón de las tijeras original...
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
                      child: Icon(
                        Icons.location_on,
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                    const Positioned(
                      right: -1,
                      bottom: 7,
                      child: Icon(
                        Icons.location_on,
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _handleInitialActivation(WidgetRef ref) {
    // 1️⃣ Encenem l'eina al proveïdor d'estat
    ref.read(elevationSelectionProvider.notifier).activateMapSelectionTool();

    // 2️⃣ Executem l'imant estàtic des del helper en una sola línia neta
    if (mapController != null) {
      ElevationMagnetHelper.recalcularIActualitzar(
        ref: ref,
        mapController: mapController!,
      );
    }
  }
}
