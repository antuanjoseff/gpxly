import 'package:flutter/material.dart';
import 'package:senda/screens/elevations/constants/chart_constants.dart';

class LayoutUtils {
  final double chartHeight;
  final double maxStackHeight;
  final bool isPanelActive;

  LayoutUtils({
    required this.chartHeight,
    required this.maxStackHeight,
    required this.isPanelActive,
  });

  factory LayoutUtils.fromContext(
    BuildContext context, {
    required bool isChartCollapsed,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final chartHeight = screenHeight * kElevationChartHeightRatio;

    final maxStackHeight = isChartCollapsed
        ? (64.0 + MediaQuery.of(context).padding.bottom + 60.0)
        : (64.0 + chartHeight + MediaQuery.of(context).padding.bottom + 60.0);

    return LayoutUtils(
      chartHeight: chartHeight,
      maxStackHeight: maxStackHeight,
      isPanelActive: true,
    );
  }
}
