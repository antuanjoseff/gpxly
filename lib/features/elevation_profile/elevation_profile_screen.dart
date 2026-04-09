import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/utils/decimation_utils.dart';
import 'package:gpxly/utils/distance_utils.dart';
import 'package:gpxly/utils/segment_stats.dart';
import 'models/touch_data.dart';

// Painters
import 'painters/range_highlight_painter.dart';
import 'painters/selection_painter.dart';

// Widgets
import 'widgets/slider_tooltip.dart';

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

  RangeValues selectedRange = const RangeValues(0, 1);
  bool isSliderActive = false;

  // -----------------------------
  // DECIMACIÓ PER A INTERACCIÓ TÀCTIL
  // -----------------------------
  TouchData _buildTouchData(
    List<double> distances,
    List<double> altitudes,
    double chartWidth,
  ) {
    final maxTouchPoints = (chartWidth * 2).round().clamp(200, 2000);
    final d2 = decimateList(distances, maxTouchPoints);
    final a2 = decimateList(altitudes, maxTouchPoints);
    return TouchData(d2, a2);
  }

  // -----------------------------
  // TOUCH SOBRE EL GRÀFIC
  // -----------------------------
  void _handleGlobalTouch(
    Offset globalPos,
    List<double> distances,
    List<double> altitudes,
  ) {
    if (isSliderActive) return; // NO seleccionar si el slider està actiu

    if (chartKey.currentContext == null) return;

    final box = chartKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPos);

    const double horizontalPadding = 24.0;
    final double left = horizontalPadding;
    final double right = box.size.width - horizontalPadding;

    if (local.dx < left || local.dx > right) {
      if (selectedIndex != null) {
        setState(() => selectedIndex = null);
      }
      return;
    }

    final maxDist = distances.last;
    final xValue = (local.dx / box.size.width) * maxDist;

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
  // RANG → ÍNDEXS
  // -----------------------------
  (int, int) _rangeToIndexes(List<double> distances) {
    if (distances.isEmpty) return (0, 0);

    final maxIndex = distances.length - 1;

    final start = (selectedRange.start * maxIndex).round().clamp(0, maxIndex);
    final end = (selectedRange.end * maxIndex).round().clamp(0, maxIndex);

    return (start <= end) ? (start, end) : (end, start);
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
    final distances = calculateDistances(coordinates);

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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    _buildHeader(context, altitudes, distances),

                    const SizedBox(height: 30),

                    // -----------------------------
                    // GRÀFIC + HIGHLIGHT + TOUCH
                    // -----------------------------
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: LayoutBuilder(
                        builder: (context, chartConstraints) {
                          final touchData = _buildTouchData(
                            distances,
                            altitudes,
                            chartConstraints.maxWidth,
                          );

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (d) => _handleGlobalTouch(
                              d.globalPosition,
                              touchData.distances,
                              touchData.altitudes,
                            ),
                            onPanUpdate: (d) => _handleGlobalTouch(
                              d.globalPosition,
                              touchData.distances,
                              touchData.altitudes,
                            ),
                            child: Stack(
                              children: [
                                // HIGHLIGHT DEL TRAM
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: CustomPaint(
                                      painter: RangeHighlightPainter(
                                        range: selectedRange,
                                        color: Colors.orange.withOpacity(0.25),
                                      ),
                                    ),
                                  ),
                                ),

                                // GRÀFIC
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  key: chartKey,
                                  child: LineChart(
                                    _buildChartData(
                                      context,
                                      altitudes,
                                      distances,
                                    ),
                                  ),
                                ),

                                // SELECCIÓ TÀCTIL
                                if (selectedIndex != null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: SelectionPainter(
                                        chartKey: chartKey,
                                        distances: distances,
                                        altitudes: altitudes,
                                        selectedIndex: selectedIndex!,
                                        lineColor: Colors.black.withAlpha(80),
                                        dotColor: Colors.white,
                                        dotBorderColor: colors.primary,
                                        isSliderActive: isSliderActive,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // -----------------------------
                    // RANGE SLIDER + TOOLTIP
                    // -----------------------------
                    LayoutBuilder(
                      builder: (context, sliderConstraints) {
                        final sliderWidth = sliderConstraints.maxWidth;
                        final (startIndex, endIndex) = _rangeToIndexes(
                          distances,
                        );

                        final startX = selectedRange.start * sliderWidth;
                        final endX = selectedRange.end * sliderWidth;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: RangeSlider(
                                values: selectedRange,
                                onChanged: (values) {
                                  setState(() {
                                    selectedRange = values;
                                    isSliderActive = true;
                                  });
                                },
                                onChangeEnd: (_) {
                                  setState(() => isSliderActive = false);
                                },
                                divisions: distances.length > 1
                                    ? distances.length - 1
                                    : null,
                              ),
                            ),

                            if (isSliderActive) ...[
                              Positioned(
                                left: 24 + startX - 20,
                                top: -55,
                                child: SliderTooltip(
                                  distance: formatDistance(
                                    distances[startIndex],
                                  ),
                                  altitude:
                                      "${altitudes[startIndex].toStringAsFixed(1)} m",
                                ),
                              ),
                              Positioned(
                                left: 24 + endX - 20,
                                top: -55,
                                child: SliderTooltip(
                                  distance: formatDistance(distances[endIndex]),
                                  altitude:
                                      "${altitudes[endIndex].toStringAsFixed(1)} m",
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    // -----------------------------
                    // INFORMACIÓ DEL TRAM
                    // -----------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Builder(
                        builder: (_) {
                          final (startIndex, endIndex) = _rangeToIndexes(
                            distances,
                          );

                          final stats = segmentStats(
                            distances,
                            altitudes,
                            startIndex,
                            endIndex,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tram seleccionat",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Distància: ${formatDistance(stats["distance"] ?? 0)}",
                              ),
                              Text(
                                "Altitud mínima: ${(stats["minAlt"] ?? 0).toStringAsFixed(1)} m",
                              ),
                              Text(
                                "Altitud màxima: ${(stats["maxAlt"] ?? 0).toStringAsFixed(1)} m",
                              ),
                              Text(
                                "Desnivell +: ${(stats["ascent"] ?? 0).toStringAsFixed(1)} m",
                              ),
                              Text(
                                "Desnivell -: ${(stats["descent"] ?? 0).toStringAsFixed(1)} m",
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // ------------------------------------------------------------
  // HEADER SUPERIOR
  // ------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    List<double> alts,
    List<double> dists,
  ) {
    final colors = Theme.of(context).colorScheme;

    final headerHeight = MediaQuery.of(context).size.height * 0.08;

    return SizedBox(
      height: headerHeight,
      child: Center(
        child: selectedIndex == null
            ? Text(
                "Llisca sobre el gràfic",
                style: TextStyle(color: colors.onSurface.withAlpha(100)),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Text(
                      "${alts[selectedIndex!].toStringAsFixed(1)} m",
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatDistance(dists[selectedIndex!]),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ------------------------------------------------------------
  // GRÀFIC (FLChart)
  // ------------------------------------------------------------
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
                  formatDistance(value),
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
        enabled: true,
        touchTooltipData: LineTouchTooltipData(getTooltipItems: (_) => []),
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
          ),
        ),
      ],
    );
  }
}
