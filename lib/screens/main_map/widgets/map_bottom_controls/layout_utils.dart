import 'package:flutter/material.dart';
import 'package:strack_rec/theme/app_dimensions.dart';

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
    final chartHeight = screenHeight * AppDimensions.elevationChartHeightRatio;

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
