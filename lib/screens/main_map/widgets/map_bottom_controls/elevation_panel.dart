import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/screens/elevations/widgets/embedded_elevation_profile.dart';
import 'package:senda/screens/elevations/widgets/segment_stats_widget.dart';
import 'package:senda/theme/app_dimensions.dart';
import 'package:senda/notifiers/segment_stats_notifier.dart';

class ElevationPanel extends ConsumerWidget {
  final bool isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  // Eliminem la dependència rígida de les variables del pare!
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
    // 🚀 LLEGIM L'ESTAT CENTRALITZAT SÍNCRON AUTOMÀTIC:
    // Riverpod s'encarrega d'enviar el total o el segment retallat sol!
    final stats = ref.watch(segmentStatsProvider);

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double officialChartHeight =
        screenHeight * AppDimensions.elevationChartHeightRatio;
    final double panelOpenHeight = officialChartHeight + 60.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isCollapsed ? 60.0 : panelOpenHeight,
      child: Column(
        children: [
          if (!isCollapsed)
            Expanded(
              child: EmbeddedElevationProfile(
                isCollapsed: isCollapsed,
                onToggle: () => onCollapseChanged?.call(!isCollapsed),
              ),
            ),

          SegmentStatsWidget(
            distanceMeters: stats.distanceMeters,
            timeElapsedStr: stats.timeElapsedStr,
            avgSpeedStr: stats.avgSpeedStr,
            ascentMeters: stats.ascentMeters,
            descentMeters: stats.descentMeters,
            onTap: () => onCollapseChanged?.call(!isCollapsed),
          ),
        ],
      ),
    );
  }
}
