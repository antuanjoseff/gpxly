import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool isActive; // Controla si l'slider es pot moure (onChanged != null)
  final bool isStyleActive; // Controla si el bloc es pinta de blau o de gris
  final ValueChanged<double> onChanged;
  final ValueChanged<double>?
  onChangeEnd; // 🎯 AFEGIT: Callback de finalització del gest
  final IconData? icon;
  final Widget? extraChild;

  const SettingsCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    this.divisions = 20,
    this.isActive = true,
    this.isStyleActive = true, // Nova propietat
    required this.onChanged,
    this.onChangeEnd, // 🎯 AFEGIT: Nou paràmetre al constructor secundari
    this.icon,
    this.extraChild,
  });

  @override
  Widget build(BuildContext context) {
    // El color de tots els elements depèn de isStyleActive
    final Color currentColor = isStyleActive ? AppColors.primary : Colors.grey;
    final Color textColor = isStyleActive
        ? AppColors.primary
        : Colors.grey[600]!;
    final Color badgeColor = isStyleActive
        ? AppColors.primary
        : Colors.grey[200]!;
    final Color badgeTextColor = isStyleActive
        ? Colors.white
        : Colors.grey[600]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStyleActive
              ? AppColors.primary.withAlpha(80)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: currentColor, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSliderRow(context, currentColor),
          if (extraChild != null) ...[const SizedBox(height: 16), extraChild!],
        ],
      ),
    );
  }

  Widget _buildSliderRow(BuildContext context, Color color) {
    final step = (max - min) / divisions;

    return Row(
      children: [
        IconButton(
          onPressed: isActive && value > min
              ? () {
                  final nouValor = (value - step).clamp(min, max);
                  onChanged(nouValor);
                  // 🎯 Executa directament l'apply si es polsa el botó de decrement
                  onChangeEnd?.call(nouValor);
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 28),
          color: color,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.black.withAlpha(20),
              trackHeight: 6,
              thumbColor: color,
              overlayColor: color.withAlpha(30),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              // HABILITACIÓ REAL: Només depèn de isActive
              onChanged: isActive ? onChanged : null,
              // 🎯 ENLLAÇ REAL AMB EL SLIDER: S'activa únicament en aixecar el dit
              onChangeEnd: isActive ? onChangeEnd : null,
            ),
          ),
        ),
        IconButton(
          onPressed: isActive && value < max
              ? () {
                  final nouValor = (value + step).clamp(min, max);
                  onChanged(nouValor);
                  // 🎯 Executa directament l'apply si es polsa el botó d'increment
                  onChangeEnd?.call(nouValor);
                }
              : null,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          color: color,
        ),
      ],
    );
  }
}

// Widget auxiliar per als títols de secció (Grisos, en majúscules)
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
