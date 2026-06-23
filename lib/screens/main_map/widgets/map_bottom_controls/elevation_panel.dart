import 'package:flutter/material.dart';
import 'package:senda/screens/elevations/widgets/embedded_elevation_profile.dart';

class ElevationPanel extends StatelessWidget {
  final bool isCollapsed;

  /// Callback cap al MapScreen quan el panell es col·lapsa o expandeix
  final ValueChanged<bool>? onCollapseChanged;

  const ElevationPanel({
    super.key,
    required this.isCollapsed,
    this.onCollapseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isCollapsed ? 0 : 220, // altura fixa del panell flotant
      child: EmbeddedElevationProfile(
        isCollapsed: isCollapsed,
        onToggle: () {
          final newValue = !isCollapsed;
          onCollapseChanged?.call(newValue);
        },
      ),
    );
  }
}
