import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/screens/stats/charts/elevation_chart.dart';
import 'package:senda/screens/stats/charts/slope_chart.dart';
import 'package:senda/screens/stats/charts/speed_chart.dart';
import 'package:senda/screens/stats/models/stat_chart_type.dart';
import 'package:senda/theme/app_colors.dart';

class StatDetailScreen extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueReal;
  final String? valueImported;
  final Track? realTrack;
  final Track? importedTrack;
  final StatChartType chartType;

  const StatDetailScreen({
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
    final t = AppLocalizations.of(context)!;
    final hasReal = realTrack != null && realTrack!.coordinates.isNotEmpty;
    final hasImported =
        importedTrack != null && importedTrack!.coordinates.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(label), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TÍTOL PER SOBRE DEL GRÀFIC ---
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      t.statDetailChartProfile(label.toUpperCase()), // l10n
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // --- CARD DEL GRÀFIC ---
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildChart(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- TARGETES DE DADES ---
                  if (hasReal)
                    _buildDataCard(
                      title: t.statDetailRecordingData,
                      value: valueReal,
                      color: AppColors.redAlert,
                      subtitle: t.statDetailRealTrackSubtitle,
                    ),

                  if (hasImported && valueImported != null) ...[
                    const SizedBox(height: 20),
                    _buildDataCard(
                      title: t.statDetailReferenceData,
                      value: valueImported!,
                      color: AppColors.trackGreen,
                      subtitle: t.statDetailImportedTrackSubtitle,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // --- BOTÓ FIX INFERIOR ---
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    t.statDetailBackButton,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
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

  Widget _buildDataCard({
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
