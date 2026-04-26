import 'package:flutter/material.dart';

Widget wpButton({
  required IconData icon,
  required bool active,
  required Color activeColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withAlpha(64) // 0.25 → 64
            : Colors.white.withAlpha(26), // 0.10 → 26
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? activeColor : Colors.white.withAlpha(38), // 0.15 → 38
          width: active ? 2 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: active ? activeColor : Colors.white.withAlpha(179), // 0.70 → 179
        size: 22,
      ),
    ),
  );
}
