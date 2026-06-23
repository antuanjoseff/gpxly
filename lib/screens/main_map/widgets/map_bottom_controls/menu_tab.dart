// lib/screens/main_map/widgets/map_bottom_controls/menu_tab.dart

import 'package:flutter/material.dart';

class MenuTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const MenuTab({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 CORREGIDO: Eliminamos el 'Expanded' de la raíz para sanear la jerarquía lineal
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint("👉 TAP REBUT A MenuTab: $label");
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        // 🎯 Usamos un Padding controlado para que las pestañas respiren de forma simétrica
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Forzamos que ocupe solo el espacio necesario
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
