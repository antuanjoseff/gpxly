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
  // ... (les teves variables es mantenen igual)

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 2,
      ), // Més espai entre elles
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // 1. OMBRA MÉS DEFINIDA: Per donar sensació de botó elevat
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // 2. VORA SUBTIL: Perquè la targeta no es perdi en fons blancs
        border: Border.all(color: Colors.grey.withAlpha(30), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            // 3. COLOR DE PRESIÓ: Fem que el feedback visual sigui més fort
            splashColor: AppColors.primary.withAlpha(30),
            highlightColor: AppColors.primary.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.all(
                16,
              ), // Més padding per fer-ho "gran"
              child: Row(
                children: [
                  // ICONA AMB MÉS FORÇA
                  SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: AppColors
                              .primary, // Blau sòlid per a més visibilitat
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label
                              .toUpperCase(), // Majúscules per estil "instrument"
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900, // Pes màxim
                            color: Colors.grey.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // VALORS (Més grans i definits)
                  Expanded(
                    child: _valueBox(
                      value: valueReal,
                      color: AppColors.redAlert,
                      label: "REAL",
                    ),
                  ),

                  if (valueImported != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _valueBox(
                        value: valueImported!,
                        color: AppColors.trackGreen,
                        label: "IMP.",
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Box de valor millorada per semblar un "display" digital
  Widget _valueBox({
    required String value,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(25), // Fons una mica més saturat
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withAlpha(60),
              width: 1.5,
            ), // Vora més gruixuda
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // Text una mica més gran
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
