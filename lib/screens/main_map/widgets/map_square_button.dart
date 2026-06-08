// lib/widgets/map_square_button.dart
import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';

enum MapButtonStyle {
  control, // 🛠️ Superiors: Fons color de l'App (AppColors.primary), icona blanca.
  action, // 🔴 Inferiors: Fons color de l'App (AppColors.primary), icona vermella elèctrica.
}

class MapSquareButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final MapButtonStyle style;

  const MapSquareButton({
    super.key,
    this.icon,
    this.child,
    this.onTap,
    this.style =
        MapButtonStyle.control, // Per defecte és el control superior de marca
  });

  @override
  Widget build(BuildContext context) {
    final bool isAction = style == MapButtonStyle.action;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        // 🟢 TOTS ELS BOTONS DEL MAPA COMPARTEIXEN ARA EL MATEIX FONS SÒLID CORPORATIU
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(
          isAction ? 16 : 12,
        ), // Un pèl més arrodonit l'inferior d'acció
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isAction ? 35 : 25),
            blurRadius: isAction ? 8 : 6,
            offset: Offset(0, isAction ? 3 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isAction ? 16 : 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child:
                  child ??
                  (icon != null
                      ? Icon(
                          icon,
                          // 🟢 Superiors: Icona blanca | 🔴 Inferiors: Vermell elèctric d'acció/gravació
                          color: isAction ? AppColors.redAlert : Colors.white,
                          size: isAction ? 24 : 22,
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
