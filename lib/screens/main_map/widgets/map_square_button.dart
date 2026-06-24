// lib/widgets/map_square_button.dart (MIDA FIXA CORPORATIVA DE 56PX)
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

    // 🚀 RECTIFICACIÓ SÍNCRONA DE GRANELL:
    // - Passem de 48px a 56px de diàmetre horitzontal i vertical.
    // - D'aquesta manera queden exactament igual d'amples i alts que el botó de les tisores.
    // - Deixem el border-radius en 16.0 perquè conservi la forma quadrada arrodonida.
    final double buttonSize = 56.0;
    final double currentRadius = isAction
        ? 18.0
        : 16.0; // 🎯 Pugem una mica el radi proporcionalment

    return Container(
      width: buttonSize, // 🎯 56px d'ample
      height: buttonSize, // 🎯 56px d'alt
      decoration: BoxDecoration(
        // 🟢 TOTS ELS BOTONS DEL MAPA COMPARTEIXEN ARA EL MATEIX FONS SÒLID CORPORATIU
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(currentRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isAction ? 35 : 25),
            blurRadius: isAction ? 8 : 6,
            offset: Offset(0, isAction ? 3 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(currentRadius),
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
                          size: isAction
                              ? 26
                              : 24, // 🎯 Pugem una mica la icona (de 22 a 24) perquè acompanyi la nova mida
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
