import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/theme/app_colors.dart';

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndex;
  final chartKey = GlobalKey();

  // -----------------------------
  // DISTÀNCIES ACUMULADES
  // -----------------------------
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

  // -----------------------------
  // DRAG GLOBAL → PROJECTAR SOBRE EL GRÀFIC
  // -----------------------------
  void _handleGlobalTouch(
    Offset globalPos,
    List<double> distances,
    List<double> altitudes,
  ) {
    if (chartKey.currentContext == null) return;

    final box = chartKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPos);

    // Fora del gràfic
    if (local.dx < 0 || local.dx > box.size.width) return;

    // Convertir píxels → distància
    final maxDist = distances.last;
    final xValue = (local.dx / box.size.width) * maxDist;

    // Trobar el punt més proper
    int index = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < distances.length; i++) {
      final diff = (distances[i] - xValue).abs();
      if (diff < minDiff) {
        minDiff = diff;
        index = i;
      }
    }

    setState(() => selectedIndex = index);
  }

  // -----------------------------
  // BUILD
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final colors = Theme.of(context).colorScheme;

    final altitudes = track.altitudes;
    final coordinates = track.coordinates;
    final distances = _calculateDistances(coordinates);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text("Perfil d'elevació")),
      body: altitudes.isEmpty
          ? Center(
              child: Text(
                "Sense dades",
                style: TextStyle(color: colors.onSurface.withAlpha(100)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanDown: (d) => _handleGlobalTouch(
                    d.globalPosition,
                    distances,
                    altitudes,
                  ),
                  onPanUpdate: (d) => _handleGlobalTouch(
                    d.globalPosition,
                    distances,
                    altitudes,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      _buildHeader(context, altitudes, distances),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Stack(
                          children: [
                            // GRÀFIC
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: LineChart(
                                _buildChartData(context, altitudes, distances),
                                key: chartKey,
                              ),
                            ),

                            // LÍNIA + PUNT DIBUIXATS A SOBRE
                            if (selectedIndex != null)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SelectionPainter(
                                    chartKey: chartKey,
                                    distances: distances,
                                    altitudes: altitudes,
                                    selectedIndex: selectedIndex!,
                                    lineColor: Colors.black.withAlpha(80),
                                    dotColor: Colors.white,
                                    dotBorderColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // -----------------------------
  // HEADER SUPERIOR
  // -----------------------------
  Widget _buildHeader(
    BuildContext context,
    List<double> alts,
    List<double> dists,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (selectedIndex == null) {
      return Text(
        "Llisca sobre el gràfic",
        style: TextStyle(color: colors.onSurface.withAlpha(100)),
      );
    }

    final i = selectedIndex!;

    return Column(
      children: [
        Text(
          "${alts[i].toStringAsFixed(1)} m",
          style: TextStyle(
            color: colors.primary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _formatDistance(dists[i]),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // GRÀFIC
  // -----------------------------
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

      // -----------------------------
      // TOUCH: LÍNIA + DOT, SENSE TEXT
      // -----------------------------
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (_) => [], // ❌ elimina text
        ),
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> indicators) {
              return indicators.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.black.withAlpha(80), strokeWidth: 1),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: colors.primary,
                      );
                    },
                  ),
                );
              }).toList();
            },
      ),

      // -----------------------------
      // LÍNIA PRINCIPAL
      // -----------------------------
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors.secondary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.secondary.withAlpha(120),
            // gradient: LinearGradient(
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            //   colors: [
            //     colors.secondary.withAlpha(10),
            //     colors.secondary.withAlpha(150),
            //   ],
            // ),
          ),
        ),
      ],
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final GlobalKey chartKey;
  final List<double> distances;
  final List<double> altitudes;
  final int selectedIndex;
  final Color lineColor;
  final Color dotColor;
  final Color dotBorderColor;

  _SelectionPainter({
    required this.chartKey,
    required this.distances,
    required this.altitudes,
    required this.selectedIndex,
    required this.lineColor,
    required this.dotColor,
    required this.dotBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final box = chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final chartSize = box.size;

    // Convertim distància → posició X
    final maxDist = distances.last;
    final x = (distances[selectedIndex] / maxDist) * chartSize.width;

    // Límits verticals del gràfic
    final double topPadding = 0;
    final double bottomPadding = 40; // espai de l’eix X

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final dotPaint = Paint()..color = dotColor;

    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dibuixar línia vertical sense tallar l’eix X
    canvas.drawLine(
      Offset(x, topPadding),
      Offset(x, chartSize.height - bottomPadding),
      linePaint,
    );

    // Dibuixar punt
    final y = _altitudeToY(
      altitudes[selectedIndex],
      altitudes,
      chartSize.height - bottomPadding,
    );

    canvas.drawCircle(Offset(x, y), 4, dotPaint);
    canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
  }

  double _altitudeToY(double alt, List<double> alts, double height) {
    final minAlt = alts.reduce((a, b) => a < b ? a : b);
    final maxAlt = alts.reduce((a, b) => a > b ? a : b);
    final norm = (alt - minAlt) / (maxAlt - minAlt);
    return height - (norm * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
