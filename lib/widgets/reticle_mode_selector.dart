import 'package:flutter/material.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/screens/main_map/widgets/map_selection_reticle.dart';

class ReticleModeSelector extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const ReticleModeSelector({
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
            child: SizedBox(
              width: 36,
              height: 36,
              child: MapSelectionReticle(
                color: Colors.white,
              ), // La teva icona de retícula
            ),
          ),
        ),
      ),
    );
  }
}
