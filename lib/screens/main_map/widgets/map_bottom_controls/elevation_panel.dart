// lib/screens/elevations/widgets/elevation_panel.dart (CORREGIT)
import 'package:flutter/material.dart';
import 'package:senda/screens/elevations/widgets/embedded_elevation_profile.dart';
import 'package:senda/screens/elevations/widgets/segment_stats_widget.dart';
import 'package:senda/theme/app_dimensions.dart'; // 👈 Importem les constants de dimensions

class ElevationPanel extends StatelessWidget {
  final bool isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  final double distanceMeters;
  final String timeElapsedStr;
  final String avgSpeedStr;
  final double ascentMeters;
  final double descentMeters;

  const ElevationPanel({
    super.key,
    required this.isCollapsed,
    this.onCollapseChanged,
    required this.distanceMeters,
    required this.timeElapsedStr,
    required this.avgSpeedStr,
    required this.ascentMeters,
    required this.descentMeters,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 1. Calculem l'alçada exacta del gràfic llegint el 15% oficial de la pantalla
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double officialChartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    // 🎯 2. L'alçada total del panell quan està obert serà el 15% del gràfic + 60 píxels de la barra de stats
    final double panelOpenHeight = officialChartHeight + 60.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // 🎯 Substituïm el 260 fix per la mida oficial lligada a la constant
      height: isCollapsed ? 60.0 : panelOpenHeight,
      child: Column(
        children: [
          // 🟦 Gràfic només quan està desplegat (ocupa l'espai restant proporcional)
          if (!isCollapsed)
            Expanded(
              child: EmbeddedElevationProfile(
                isCollapsed: isCollapsed,
                onToggle: () => onCollapseChanged?.call(!isCollapsed),
              ),
            ),

          // 🟩 Barra d’estadístiques (ocupa sempre 60 píxels de forma fixa a baix)
          SegmentStatsWidget(
            distanceMeters: distanceMeters,
            timeElapsedStr: timeElapsedStr,
            avgSpeedStr: avgSpeedStr,
            ascentMeters: ascentMeters,
            descentMeters: descentMeters,
            onTap: () => onCollapseChanged?.call(!isCollapsed),
          ),
        ],
      ),
    );
  }
}
