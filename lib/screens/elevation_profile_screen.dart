import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:geolocator/geolocator.dart';

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndex;

  List<double> _calculateDistances(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return [];

    List<double> distances = [0.0];
    double total = 0.0;

    for (int i = 0; i < coordinates.length - 1; i++) {
      total += Geolocator.distanceBetween(
        coordinates[i][1],
        coordinates[i][0],
        coordinates[i + 1][1],
        coordinates[i + 1][0],
      );
      distances.add(total);
    }
    return distances;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.toStringAsFixed(0)}m";
    return "${(meters / 1000).toStringAsFixed(2)}km";
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final colors = Theme.of(context).colorScheme;

    final altitudes = track.altitudes;
    final coordinates = track.coordinates;
    final distances = _calculateDistances(coordinates);

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil d'elevació")),
      body: altitudes.isEmpty
          ? Center(
              child: Text(
                "Sense dades",
                style: TextStyle(color: colors.onSurface.withOpacity(0.4)),
              ),
            )
          : OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSelectionHeader(
                          context,
                          altitudes,
                          distances,
                          selectedIndex,
                        ),

                        SizedBox(height: isLandscape ? 10 : 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AspectRatio(
                            aspectRatio: isLandscape ? 4.0 : 2.0,
                            child: LineChart(
                              _buildChartData(context, altitudes, distances),
                            ),
                          ),
                        ),

                        if (isLandscape) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    List<double> alts,
    List<double> dists,
    int? index,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (index == null) {
      return Text(
        "Llisca sobre el gràfic",
        style: TextStyle(color: colors.onSurface.withOpacity(0.4)),
      );
    }

    return Column(
      children: [
        Text(
          "${alts[index].toStringAsFixed(1)} m",
          style: TextStyle(
            color: colors.primary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Distància: ${_formatDistance(dists[index])}",
          style: TextStyle(
            color: colors.onSurface.withOpacity(0.7),
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(
    BuildContext context,
    List<double> alts,
    List<double> dists,
  ) {
    final colors = Theme.of(context).colorScheme;

    final spots = List.generate(alts.length, (i) => FlSpot(dists[i], alts[i]));
    final maxDist = dists.last;

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: maxDist > 0 ? maxDist / 2 : 1.0,
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();

              return SideTitleWidget(
                meta: meta,
                space: 10,
                fitInside: SideTitleFitInsideData.fromTitleMeta(
                  meta,
                  enabled: true,
                ),
                child: Text(
                  _formatDistance(value),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
      ),

      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (response?.lineBarSpots != null &&
              response!.lineBarSpots!.isNotEmpty) {
            setState(
              () => selectedIndex = response.lineBarSpots!.first.spotIndex,
            );
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => Colors.transparent,
        ),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors.primary, // línia = blau cel
          barWidth: 3,
          dotData: const FlDotData(show: false),

          // GRADIENT OCRE A SOTA
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.secondary.withOpacity(0.6), // ocre intens
                colors.secondary.withOpacity(0.05), // ocre molt suau
              ],
            ),
          ),
        ),
      ],
    );
  }
}
