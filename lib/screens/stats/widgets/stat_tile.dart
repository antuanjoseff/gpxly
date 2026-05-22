import 'package:flutter/material.dart';
import 'package:senda/screens/stats/models/stat_chart_type.dart';
import 'package:senda/theme/app_colors.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;

  final String valueReal;
  final String? valueImported;

  final StatChartType chartType;

  final VoidCallback onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.valueReal,
    required this.chartType,
    required this.onTap,
    this.valueImported,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icona + etiqueta
            SizedBox(
              width: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.grey.shade600, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Valor real (vermell)
            Expanded(
              child: _valueBox(value: valueReal, color: AppColors.redAlert),
            ),

            // Valor importat (verd)
            if (valueImported != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _valueBox(
                  value: valueImported!,
                  color: AppColors.trackGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _valueBox({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 0.3,
            color: color,
          ),
        ),
      ),
    );
  }
}
