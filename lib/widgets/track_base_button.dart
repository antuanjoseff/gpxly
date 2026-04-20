import 'package:flutter/material.dart';

class TrackBaseButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onPressed;

  // Icona i text opcionals
  final IconData? icon;
  final String? text;
  final Color? iconColor;

  const TrackBaseButton({
    super.key,
    required this.color,
    required this.onPressed,
    this.icon,
    this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // alçada unificada
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Cap icona i cap text
    if (icon == null && text == null) {
      return const SizedBox.shrink();
    }

    // Només text
    if (icon == null) {
      return Text(
        text!,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    // Només icona
    if (text == null) {
      return Icon(
        icon,
        color: iconColor ?? Colors.white, // 👈 ara sí que funciona
      );
    }

    // Icona + text
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.white, // 👈 aplicat aquí també
        ),
        const SizedBox(width: 8),
        Text(
          text!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
