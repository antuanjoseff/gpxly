// lib/screens/elevations/widgets/elevation_panel.dart (NET PER AL GRÀFIC INDEPENDENT)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/screens/elevations/widgets/embedded_elevation_profile.dart';
import 'package:strack_rec/theme/app_dimensions.dart';

class ElevationPanel extends ConsumerWidget {
  final bool isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  // 🚀 Eliminem tots els paràmetres de dades velles que ja no s'han de pintar aquí!
  const ElevationPanel({
    super.key,
    required this.isCollapsed,
    this.onCollapseChanged,
    double? distanceMeters,
    String? timeElapsedStr,
    String? avgSpeedStr,
    double? ascentMeters,
    double? descentMeters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si està col·lapsat, no es pinta ni consumeix espai (mesura 0)
    if (isCollapsed) return const SizedBox.shrink();

    // Calculem l'alçada del 15% proporcional oficial de Senda
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double officialChartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: officialChartHeight, // Alçada neta per al gràfic de muntanyes
      child: EmbeddedElevationProfile(
        isCollapsed: isCollapsed,
        onToggle: () => onCollapseChanged?.call(!isCollapsed),
      ),
    );
  }
}
