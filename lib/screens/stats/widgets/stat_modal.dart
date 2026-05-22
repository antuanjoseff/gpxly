import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/screens/stats/charts/elevation_chart.dart';
import 'package:senda/screens/stats/charts/slope_chart.dart';
import 'package:senda/screens/stats/charts/speed_chart.dart';
import 'package:senda/screens/stats/models/stat_chart_type.dart';
import 'package:senda/theme/app_colors.dart';

class StatModal extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueReal;
  final String? valueImported;
  final Track? realTrack;
  final Track? importedTrack;
  final StatChartType chartType;

  const StatModal({
    super.key,
    required this.icon,
    required this.label,
    required this.valueReal,
    required this.chartType,
    this.valueImported,
    this.realTrack,
    this.importedTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Augmentem al 90% per donar molt d'espai
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // INDICADOR SUPERIOR (Visual per indicar que és un modal)
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // CAPÇALERA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 28),
                ),
              ],
            ),
          ),

          // CONTINGUT
          Expanded(
            child: SingleChildScrollView(
              // Bloquegem l'scroll perquè no interfereixi amb el gràfic
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // GRÀFIC (Alçada fixa i protegit)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 200, // Una mica més alt per llegibilitat
                      color: Colors.grey.shade50,
                      child: _buildChart(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // DADES INFERIORS
                  _detailRow("Track gravat", valueReal, AppColors.redAlert),
                  const SizedBox(height: 12),
                  if (valueImported != null)
                    _detailRow(
                      "Track importat",
                      valueImported!,
                      AppColors.trackGreen,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return switch (chartType) {
      StatChartType.elevation => ElevationChart(
        real: realTrack,
        imported: importedTrack,
      ),
      StatChartType.speed => SpeedChart(
        real: realTrack,
        imported: importedTrack,
      ),
      StatChartType.slope => SlopeChart(
        real: realTrack,
        imported: importedTrack,
      ),
    };
  }

  Widget _detailRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24, // Valors més grans
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ],
        ),
        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
      ],
    );
  }
}
