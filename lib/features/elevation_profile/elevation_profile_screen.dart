import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gpxly/features/elevation_profile/painters/selection_painter.dart';
import 'package:gpxly/features/elevation_profile/painters/range_highlight_painter.dart';
import 'package:gpxly/features/elevation_profile/utils/chart_utils.dart';

import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/elevation_progress_notifier.dart';

import 'package:gpxly/utils/distance_utils.dart';
import 'package:gpxly/utils/decimation_utils.dart';

import 'package:gpxly/ui/app_messages.dart';
import 'package:gpxly/theme/app_colors.dart';

enum ActiveHandle { none, start, end }

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  // Agulles
  int? selectedIndexGraph;
  int? selectedIndexStart;
  int? selectedIndexEnd;

  ActiveHandle activeHandle = ActiveHandle.none;
  int _draggingNeedle = 0;

  final chartKey = GlobalKey();

  // Colors
  final Color primaryNeedleColor = const Color(0xFF4CAF50); // Verd
  final Color secondaryNeedleColor = AppColors.mustardYellow; // SC1

  final Color sliderStartNeedleColor = const Color(0xFF007BFF);
  final Color sliderEndNeedleColor = const Color(0xFFFF3B30);

  // ------------------------------------------------------------
  //  Construcció del gràfic amb dos tracks
  // ------------------------------------------------------------
  LineChartData _buildChartDataTwoTracks(
    BuildContext context,
    List<double> realAlts,
    List<double> realDists,
    List<double> importedAlts,
    List<double> importedDists,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (realAlts.isEmpty && importedAlts.isEmpty) {
      return LineChartData(lineBarsData: []);
    }

    final List<double> allAlts = [...realAlts, ...importedAlts];

    final double minAlt = allAlts.reduce((a, b) => a < b ? a : b);
    final double maxAlt = allAlts.reduce((a, b) => a > b ? a : b);

    double diff = maxAlt - minAlt;
    double effectiveRange = diff < 50 ? 50 : diff;

    final forcedMinY = minAlt - (effectiveRange * 0.1);
    final forcedMaxY = forcedMinY + (effectiveRange * 1.2);

    final maxDist = [
      if (realDists.isNotEmpty) realDists.last,
      if (importedDists.isNotEmpty) importedDists.last,
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      maxX: maxDist,
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
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        // Track primari (real)
        if (realDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              realAlts.length,
              (i) => FlSpot(realDists[i], realAlts[i]),
            ),
            isCurved: false,
            color: colors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),

        // Track secundari (importat)
        if (importedDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              importedAlts.length,
              (i) => FlSpot(importedDists[i], importedAlts[i]),
            ),
            isCurved: false,
            color: AppColors.mustardYellow, // LC1
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  //  Segment Stats (C1): dues barres si hi ha dos tracks
  // ------------------------------------------------------------
  Widget _buildSegmentStatsBar(
    List<double> alts,
    List<double> dists,
    List<DateTime>? times,
    Color color,
  ) {
    if (selectedIndexStart == null || selectedIndexEnd == null) {
      return const SizedBox(height: 50);
    }

    final start = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexStart!
        : selectedIndexEnd!;
    final end = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexEnd!
        : selectedIndexStart!;

    if (end >= alts.length) return const SizedBox(height: 50);

    final distMetres = dists[end] - dists[start];

    double gain = 0;
    for (int i = start; i < end; i++) {
      double diff = alts[i + 1] - alts[i];
      if (diff > 0) gain += diff;
    }

    String durationStr = "00:00:00";
    String speedStr = "0.0 km/h";

    if (times != null && times.length > end) {
      final duration = times[end].difference(times[start]);
      durationStr = duration.toString().split('.').first.padLeft(8, "0");
      final hores = duration.inSeconds / 3600;
      if (hores > 0) {
        speedStr = "${((distMetres / 1000) / hores).toStringAsFixed(1)} km/h";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(Icons.straighten, formatDistance(distMetres)),
          _divider(),
          _stat(Icons.timer, durationStr),
          _divider(),
          _stat(Icons.speed, speedStr),
          _divider(),
          _stat(Icons.terrain, "+${gain.toStringAsFixed(0)}m"),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 14, width: 1, color: Colors.white12);

  // ------------------------------------------------------------
  //  BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);

    final realAlts = real.altitudes;
    final realDists = calculateDistances(real.coordinates);
    final realTimes = real.timestamps;

    final importedAlts = imported?.altitudes ?? <double>[];
    final importedDists = calculateDistances(imported?.coordinates ?? []);
    final importedTimes = imported?.timestamps ?? <DateTime>[];

    final hasReal = realAlts.isNotEmpty;
    final hasImported = importedAlts.isNotEmpty;

    if (!hasReal && !hasImported) {
      return Scaffold(
        appBar: AppBar(title: const Text("Perfil d'elevació")),
        body: const Center(child: Text("Sense dades")),
      );
    }

    // Track primari = més llarg
    final bool primaryIsReal =
        realDists.isNotEmpty &&
        (importedDists.isEmpty || realDists.last >= importedDists.last);

    final primaryAlts = primaryIsReal ? realAlts : importedAlts;
    final primaryDists = primaryIsReal ? realDists : importedDists;
    final primaryTimes = primaryIsReal ? realTimes : importedTimes;

    final secondaryAlts = primaryIsReal ? importedAlts : realAlts;
    final secondaryDists = primaryIsReal ? importedDists : realDists;
    final secondaryTimes = primaryIsReal ? importedTimes : realTimes;

    final chartHeight = MediaQuery.of(context).size.height * 0.3;

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil d'elevació")),
      body: Column(
        children: [
          // Barra primària
          _buildSegmentStatsBar(
            primaryAlts,
            primaryDists,
            primaryTimes,
            AppColors.tertiary,
          ),

          // Barra secundària (només si té dades dins del rang)
          if (selectedIndexStart != null &&
              selectedIndexEnd != null &&
              selectedIndexEnd! < secondaryAlts.length)
            _buildSegmentStatsBar(
              secondaryAlts,
              secondaryDists,
              secondaryTimes,
              AppColors.mustardYellow, // SC1
            ),

          const SizedBox(height: 10),

          // Llegenda
          _buildLegend(hasImported),

          // GRÀFIC
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, chartConstraints) {
                final width = chartConstraints.maxWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  // Long press → crear rang
                  onLongPressStart: (_) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      selectedIndexStart = ChartLogic.calculateIndexFromX(
                        width * 0.25,
                        width,
                        primaryDists,
                      );
                      selectedIndexEnd = ChartLogic.calculateIndexFromX(
                        width * 0.75,
                        width,
                        primaryDists,
                      );
                      selectedIndexGraph = null;
                      _draggingNeedle = 0;
                    });
                  },

                  // Pan down → decidir quina agulla movem
                  onPanDown: (details) {
                    final x = details.localPosition.dx;

                    final xStart = selectedIndexStart != null
                        ? ChartLogic.indexToX(
                            selectedIndexStart!,
                            width,
                            primaryDists,
                          )
                        : null;

                    final xEnd = selectedIndexEnd != null
                        ? ChartLogic.indexToX(
                            selectedIndexEnd!,
                            width,
                            primaryDists,
                          )
                        : null;

                    setState(() {
                      if (xStart != null && (x - xStart).abs() < 30) {
                        _draggingNeedle = 1;
                      } else if (xEnd != null && (x - xEnd).abs() < 30) {
                        _draggingNeedle = 2;
                      } else {
                        _draggingNeedle = 3;
                        selectedIndexStart = null;
                        selectedIndexEnd = null;
                        selectedIndexGraph = ChartLogic.calculateIndexFromX(
                          x,
                          width,
                          primaryDists,
                        );
                      }
                    });
                  },

                  // Pan update → moure agulles
                  onPanUpdate: (details) {
                    if (_draggingNeedle == 0) return;

                    final x = details.localPosition.dx;

                    setState(() {
                      if (_draggingNeedle == 1) {
                        selectedIndexStart = ChartLogic.calculateIndexFromX(
                          x,
                          width,
                          primaryDists,
                        );
                      } else if (_draggingNeedle == 2) {
                        selectedIndexEnd = ChartLogic.calculateIndexFromX(
                          x,
                          width,
                          primaryDists,
                        );
                      } else if (_draggingNeedle == 3) {
                        selectedIndexGraph = ChartLogic.calculateIndexFromX(
                          x,
                          width,
                          primaryDists,
                        );
                      }
                    });
                  },

                  onPanEnd: (_) => _draggingNeedle = 0,
                  onPanCancel: () => _draggingNeedle = 0,

                  child: Stack(
                    children: [
                      // Highlight del rang
                      if (selectedIndexStart != null &&
                          selectedIndexEnd != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: SelectionPainter.topReserved,
                            ),
                            child: CustomPaint(
                              painter: RangeAreaPainter(
                                startIndex: selectedIndexStart!,
                                endIndex: selectedIndexEnd!,
                                distances: primaryDists,
                                altitudes: primaryAlts,
                                minY: primaryAlts.reduce(
                                  (a, b) => a < b ? a : b,
                                ),
                                maxY: primaryAlts.reduce(
                                  (a, b) => a > b ? a : b,
                                ),
                                color: Colors.orange.withAlpha(50),
                              ),
                            ),
                          ),
                        ),

                      // Gràfic
                      Padding(
                        padding: const EdgeInsets.only(
                          top: SelectionPainter.topReserved,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LineChart(
                            _buildChartDataTwoTracks(
                              context,
                              realAlts,
                              realDists,
                              importedAlts,
                              importedDists,
                            ),
                          ),
                        ),
                      ),

                      // Agulles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SelectionPainter(
                            graphX: selectedIndexGraph != null
                                ? (primaryDists[selectedIndexGraph!] /
                                              primaryDists.last) *
                                          (chartConstraints.maxWidth - 48) +
                                      24
                                : null,
                            graphIndex: selectedIndexGraph,
                            startX: selectedIndexStart != null
                                ? ChartLogic.indexToX(
                                    selectedIndexStart!,
                                    chartConstraints.maxWidth,
                                    primaryDists,
                                  )
                                : null,
                            startIndex: selectedIndexStart,
                            endX: selectedIndexEnd != null
                                ? (primaryDists[selectedIndexEnd!] /
                                              primaryDists.last) *
                                          (chartConstraints.maxWidth - 48) +
                                      24
                                : null,
                            endIndex: selectedIndexEnd,
                            distances: primaryDists,
                            altitudes: primaryAlts,
                            secondaryDistances: secondaryDists.isNotEmpty
                                ? secondaryDists
                                : null,
                            secondaryAltitudes: secondaryAlts.isNotEmpty
                                ? secondaryAlts
                                : null,
                            graphNeedleColor: primaryNeedleColor,
                            sliderStartNeedleColor: sliderStartNeedleColor,
                            sliderEndNeedleColor: sliderEndNeedleColor,
                            secondaryGraphNeedleColor: secondaryDists.isNotEmpty
                                ? secondaryNeedleColor
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildLegend(bool hasSecondary) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        // Track primari
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), // Verd primari
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Track primari",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ),

        const SizedBox(width: 20),

        // Track secundari (només si existeix)
        if (hasSecondary)
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.mustardYellow, // Groc secundari
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Track importat",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
