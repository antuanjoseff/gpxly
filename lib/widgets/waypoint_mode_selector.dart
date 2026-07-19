import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';

class WaypointModeSelector extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const WaypointModeSelector({
    super.key,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(12),
      color: isActive ? AppColors.logoGreen : AppColors.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Icon(
              Icons.touch_app, // La teva icona de waypoint
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
