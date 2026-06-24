// lib/screens/main_map/widgets/map_stack_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/segment_stats_notifier.dart';
import 'package:senda/notifiers/nearest_track_point_notifier.dart';
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 📊 CAPA A: EL GRÀFIC D'ELEVACIONS (Persiana que llisca cap amunt)
        // 📊 CAPA A: EL GRÀFIC D'ELEVACIONS (Persiana que llisca cap amunt)
        Positioned(
          left: 0,
          right: 0,
          bottom: 60.0, // Recolzat a dalt dels 60px de la barra negra
          child: ElevationPanel(
            isCollapsed: isChartCollapsed,
            onCollapseChanged: (collapsed) {
              final newValue = !isChartCollapsed;
              onCollapseChanged(newValue);
              _notifySelectionCollapse(ref, newValue);
            },
          ),
        ),

        // 🟩 CAPA B: LA BARRA NEGRA D'ESTADÍSTIQUES (Sempre visible i fixa!)
        Positioned(
          left: 0,
          right: 0,
          // 🚀 RECTIFICACIÓ ABSOLUTA: Forcem bottom 0.0 perquè quedi 100% clavada
          // a sota de tot de la pantalla del mòbil, sense flotar.
          bottom: 0.0,
          child: SegmentStatsWidget(
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
        ),
      ],
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

/// 🚀 WIDGET MODULAR 2: ELS BOTONS FLOTANTS DE LES TISORES
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

    // 1. Obtenemos la altura proporcional exacta del gráfico cuando está abierto
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double chartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    final double bottomOffset = isChartCollapsed
        ? 40.0 + AppDimensions.mapSafetyPadding
        : 60.0 + chartHeight + AppDimensions.mapSafetyPadding;

    // A. Si l'eina està en OFF: Mostrem només les Tisores
    if (sel.mapToolState == MapSelectionToolState.off) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        right: 16,
        bottom: bottomOffset,
        child: FloatingActionButton(
          heroTag: "btn_tisores_modular",
          backgroundColor: AppColors.primary, // Fons blanco limpio
          onPressed: () => _handleAction(ref, MapSelectionToolState.off),
          child: SizedBox(
            width: 36, // Ampliamos ligeramente el contenedor interno
            height: 36,
            child: Stack(
              children: [
                // 🛤️ 1. LA LÍNEA DEL CAMINO (Bajada a la base de los marcadores)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      5, // Situada justo en la base donde terminan las puntas de los pins
                  child: Container(
                    height: 3.5, // Un poco más gruesa para que tenga presencia
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 🟢 2. MARCADOR DE INICIO (Pin verde más grande a la izquierda, apoyado sobre la línea)
                const Positioned(
                  left: -1, // Pegado al borde izquierdo (menos padding)
                  bottom:
                      7, // Elevado justo lo necesario para quedar por encima del trazo
                  child: Icon(
                    Icons.location_on,
                    size: 21, // Más grande (antes 16)
                    color: Colors.white,
                  ),
                ),

                // 🔴 3. MARCADOR DE FIN (Pin rojo más grande a la derecha, apoyado sobre la línea)
                const Positioned(
                  right: -1, // Pegado al borde derecho (menos padding)
                  bottom:
                      7, // Alineado exactamente a la misma altura que el verde
                  child: Icon(
                    Icons.location_on,
                    size: 21, // Más grande (antes 16)
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🎛️ CAS B: L'eina està encesa (Muntem la barra d'accions combinades)
    // 🎛️ CAS B: L'eina està encesa (Muntem la barra d'accions combinades simètrica)
    String label;
    IconData icon;
    Color buttonBgColor; // 🚀 NOVA VARIABLE PER AL COLOR DINÀMIC

    switch (sel.mapToolState) {
      case MapSelectionToolState.selectingStart:
        label = "Fixar inici";
        icon = Icons.my_location;
        buttonBgColor = const Color(0xFF4CAF50);
        break;
      case MapSelectionToolState.selectingEnd:
        label = "Fixar final";
        icon = Icons.flag;
        buttonBgColor = const Color(0xFFF44336);
        break;
      case MapSelectionToolState.selected:
        label = "Reiniciar";
        icon = Icons.restart_alt;
        buttonBgColor = Theme.of(
          context,
        ).primaryColor; // Blau corporatiu normal per reiniciar
        break;
      default:
        label = "";
        icon = Icons.help_outline;
        buttonBgColor = Theme.of(context).primaryColor;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      right: 16,
      bottom: bottomOffset,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔴 1. BOTÓ DE CANCEL·LAR (Ara amb fons vermell accentuat i icona blanca)
          SizedBox(
            width: 56, // Diàmetre simètric idèntic al botó d'acció gran
            height: 56,
            child: FloatingActionButton(
              heroTag: "btn_cancel_scissors_modular",
              // 🚀 CANVI DE COLORS CORPORATIUS:
              backgroundColor:
                  Colors.redAccent, // 🔴 Fons vermell per a l'acció de tancar
              foregroundColor: Colors.white, // ⬜ Icona de la "X" en blanc pur
              elevation: 6,
              onPressed: () {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .deactivateMapSelectionTool();
              },
              child: const Icon(
                Icons.close,
                size: 24,
              ), // Icona ben visible de 24px
            ),
          ),

          const SizedBox(width: AppDimensions.verticalSpacing),
          FloatingActionButton.extended(
            heroTag: "btn_action_scissors_modular",
            // 🚀 APLICQUEM EL COLOR DINÀMIC AL FONS DEL BOTÓ:
            backgroundColor: buttonBgColor,
            foregroundColor: Colors.white,
            icon: Icon(icon),
            label: Text(label),
            onPressed: () => _handleAction(ref, sel.mapToolState),
          ),
        ],
      ),
    );
  }

  void _handleAction(WidgetRef ref, MapSelectionToolState currentState) {
    final notifier = ref.read(elevationSelectionProvider.notifier);

    // Filtre de precisió geogràfica sota demanda (0ms)
    final double currentZoom = mapController?.cameraPosition?.zoom ?? 14.0;
    ref
        .read(nearestTrackPointProvider.notifier)
        .refreshNearestPoint(currentZoom: currentZoom);

    final int nearest = ref.read(nearestTrackPointProvider);

    switch (currentState) {
      case MapSelectionToolState.off:
        notifier.activateMapSelectionTool();
        break;
      case MapSelectionToolState.selectingStart:
        notifier.fixStartFromMap(nearest);
        break;
      case MapSelectionToolState.selectingEnd:
        notifier.fixEndFromMap(nearest);
        break;
      case MapSelectionToolState.selected:
        // 🚀 REINICI NET: Posem els índexs a null per forçar l'esborrat dels cercles al mapa
        notifier.resetMapSelection();
        break;
      default:
        break;
    }
  }
}
