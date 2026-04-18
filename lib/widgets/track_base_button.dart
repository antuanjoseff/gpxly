import 'package:flutter/material.dart';

class TrackBaseButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onPressed;

  // Icona i text opcionals
  final IconData? icon;
  final String? text;

  const TrackBaseButton({
    super.key,
    required this.color,
    required this.onPressed,
    this.icon,
    this.text,
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
      return Icon(icon, color: Colors.white);
    }

    // Icona + text
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
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
