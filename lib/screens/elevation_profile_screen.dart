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

// ... imports ...

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndex;

  List<double> _calculateDistances(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return [];

    List<double> distances = [0.0];
    double total = 0.0;

    for (int i = 0; i < coordinates.length - 1; i++) {
      total += Geolocator.distanceBetween(
        coordinates[i][1], // latitud origen
        coordinates[i][0], // longitud origen
        coordinates[i + 1][1], // latitud destí
        coordinates[i + 1][0], // longitud destí
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
    final altitudes = track.altitudes;
    final coordinates = track.coordinates;
    final distances = _calculateDistances(coordinates);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Perfil d'elevació"),
        backgroundColor: Colors.black,
      ),
      body: altitudes.isEmpty
          ? const Center(
              child: Text(
                "Sense dades",
                style: TextStyle(color: Colors.white24),
              ),
            )
          : OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                return Center(
                  child: SingleChildScrollView(
                    // Evita errors de mida en pantalles petites
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. INFO DINÀMICA (Sempre a sobre)
                        _buildSelectionHeader(
                          altitudes,
                          distances,
                          selectedIndex,
                        ),

                        // Ajustem l'espai segons l'orientació
                        SizedBox(height: isLandscape ? 10 : 40),

                        // 2. EL GRÀFIC
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AspectRatio(
                            // MÉS PANORÀMIC EN HORITZONTAL (4.0 o 3.0)
                            aspectRatio: isLandscape ? 4.0 : 2.0,
                            child: LineChart(
                              _buildChartData(altitudes, distances),
                            ),
                          ),
                        ),

                        // Espai extra a sota per estètica en horitzontal
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
    List<double> alts,
    List<double> dists,
    int? index,
  ) {
    if (index == null)
      return const Text(
        "Llisca sobre el gràfic",
        style: TextStyle(color: Colors.white38),
      );

    return Column(
      children: [
        Text(
          "${alts[index].toStringAsFixed(1)} m",
          style: const TextStyle(
            color: Color(0xFF00E676),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Distància: ${_formatDistance(dists[index])}",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<double> alts, List<double> dists) {
    final spots = List.generate(alts.length, (i) => FlSpot(dists[i], alts[i]));
    final maxDist = dists.last;

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      // CONFIGURACIÓ DE LES ETIQUETES 25, 50, 75, 100%
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // Una mica més d'espai vertical per si de cas
            interval: maxDist > 0 ? maxDist / 2 : 1.0,

            // AQUESTA ÉS LA PROPIETAT MÀGICA:
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();

              return SideTitleWidget(
                meta: meta,
                space: 10,
                // Força que el text de la punta dreta es mogui cap a l'esquerra per no sortir
                fitInside: SideTitleFitInsideData.fromTitleMeta(
                  meta,
                  enabled: true,
                ),
                child: Text(
                  _formatDistance(value),
                  style: const TextStyle(
                    color: Colors.white,
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
        // TREU EL 'const' D'AQUÍ SOTA
        touchTooltipData: LineTouchTooltipData(
          // En lloc de null, usem una funció que retorna transparent
          getTooltipColor: (LineBarSpot spot) => Colors.transparent,
        ),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF00E676),
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(
                  0xFF00E676,
                ).withAlpha(150), // Verd neó a dalt (prop de la línia)
                const Color(
                  0xFF00E676,
                ).withAlpha(10), // Gairebé negre a la base
              ],
            ),
          ),
        ),
      ],
    );
  }
}
