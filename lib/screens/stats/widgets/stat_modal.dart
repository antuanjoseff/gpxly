import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/screens/stats/charts/elevation_chart.dart';
import 'package:senda/screens/stats/charts/slope_chart.dart';
import 'package:senda/screens/stats/charts/speed_chart.dart';
import 'package:senda/screens/stats/widgets/stat_header.dart';
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
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Títol ---
            Row(
              children: [
                Icon(icon, size: 26, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- GRÀFIC ---
            SizedBox(height: 160, child: _buildChart()),

            const SizedBox(height: 20),

            // --- Valors ampliats ---
            _detailRow("Track gravat", valueReal, AppColors.redAlert),
            if (valueImported != null)
              _detailRow(
                "Track importat",
                valueImported!,
                AppColors.trackGreen,
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- Selecció del gràfic ---
  Widget _buildChart() {
    switch (chartType) {
      case StatChartType.elevation:
        return ElevationChart(real: realTrack, imported: importedTrack);

      case StatChartType.speed:
        return SpeedChart(real: realTrack, imported: importedTrack);

      case StatChartType.slope:
        return SlopeChart(real: realTrack, imported: importedTrack);
    }
  }

  // --- Files de valors ---
  Widget _detailRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
