import 'package:flutter/material.dart';
import 'package:senda/widgets/embedded_elevation_profile.dart';

class ElevationPanel extends StatelessWidget {
  final bool isVisible;
  final bool isCollapsed;
  final double chartHeight;
  final bool isSubMenuOpen;
  final VoidCallback onToggle;

  const ElevationPanel({
    super.key,
    required this.isVisible,
    required this.isCollapsed,
    required this.chartHeight,
    required this.isSubMenuOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 64.0 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSubMenuOpen ? 0.35 : 1.0,
        child: IgnorePointer(
          ignoring: isSubMenuOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isCollapsed ? 0.0 : chartHeight,
            child: EmbeddedElevationProfile(
              isCollapsed: isCollapsed,
              onToggle: onToggle,
            ),
          ),
        ),
      ),
    );
  }
}
