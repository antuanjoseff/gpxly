import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gpxly/features/elevation_profile/painters/selection_painter.dart';
import 'package:gpxly/features/elevation_profile/painters/range_highlight_painter.dart';
import 'package:gpxly/features/elevation_profile/utils/chart_utils.dart';

import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/utils/distance_utils.dart';
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
  double statsHeight = 120;

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

    final bool primaryIsReal =
        realDists.isNotEmpty &&
        (importedDists.isEmpty || realDists.last >= importedDists.last);

    final List<double> primaryDists = primaryIsReal ? realDists : importedDists;

    final List<double> primaryAlts = primaryIsReal ? realAlts : importedAlts;

    final List<double> secondaryDists = primaryIsReal
        ? importedDists
        : realDists;

    final List<double> secondaryAlts = primaryIsReal ? importedAlts : realAlts;

    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      maxX: maxDist,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: forcedMinY, // 👈 línia a l’eix X
            color: Colors.grey, // o el color que vulguis
            strokeWidth: 1.5,
          ),
        ],
      ),

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
        // TRACK PRIMARI (El que marca la longitud de l'eix X)
        LineChartBarData(
          spots: List.generate(
            primaryAlts.length,
            (i) => FlSpot(primaryDists[i], primaryAlts[i]),
          ),
          isCurved: false,
          // Si el primari és el real -> secondary. Si no (és l'importat) -> primary.
          color: primaryIsReal ? AppColors.secondary : AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: (primaryIsReal ? AppColors.secondary : AppColors.primary)
                .withAlpha(primaryIsReal ? 64 : 32),
            cutOffY: forcedMinY,
            applyCutOffY: true,
          ),
        ),

        // TRACK SECUNDARI (L'altre track, si existeix)
        if (secondaryDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              secondaryAlts.length,
              (i) => FlSpot(secondaryDists[i], secondaryAlts[i]),
            ),
            isCurved: false,
            // Si el primari era el real, el secundari és l'importat -> primary.
            // Si el primari era l'importat, el secundari és el real -> secondary.
            color: primaryIsReal ? AppColors.primary : AppColors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (primaryIsReal ? AppColors.primary : AppColors.secondary)
                  .withAlpha(primaryIsReal ? 32 : 64),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  //  Segment Stats (C1): dues barres si hi ha dos tracks
  // ------------------------------------------------------------
  int mapIndexByDistance(
    int primaryIndex,
    List<double> primaryDists,
    List<double> secondaryDists,
  ) {
    if (primaryIndex < 0 || primaryIndex >= primaryDists.length) {
      return 0;
    }

    final dist = primaryDists[primaryIndex];

    for (int i = 0; i < secondaryDists.length; i++) {
      if (secondaryDists[i] >= dist) return i;
    }

    return secondaryDists.length - 1;
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _tileStat(Icons.straighten, formatDistance(distMetres)),
          _verticalDivider(),
          _tileStat(Icons.timer, durationStr),
          _verticalDivider(),
          _tileStat(Icons.speed, speedStr),
          _verticalDivider(),
          _tileStat(Icons.terrain, "+${gain.toStringAsFixed(0)}m"),
        ],
      ),
    );
  }

  Widget _tileStat(IconData icon, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

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
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text("Perfil d'elevació"),
        ),
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
    final track = ref.watch(trackProvider);
    final importedTrack = ref.watch(importedTrackProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil d'elevació")),
      body: Column(
        children: [
          SizedBox(height: 20),
          // ─────────────────────────────────────────────
          // 1) BLOC D’ESTADÍSTIQUES AMB ALÇADA FIXA
          // ─────────────────────────────────────────────
          SizedBox(
            height: 120, // ← ajusta si vols més o menys espai
            child: Column(
              children: [
                if (selectedIndexStart != null && selectedIndexEnd != null) ...[
                  // TRACK REAL
                  if (track.distances.isNotEmpty)
                    _buildSegmentStatsBar(
                      track.altitudes,
                      track.distances,
                      track.timestamps,
                      AppColors.secondary,
                    ),

                  const SizedBox(height: 8),

                  // TRACK IMPORTAT
                  if (importedTrack != null &&
                      importedTrack.distances.isNotEmpty)
                    Builder(
                      builder: (_) {
                        final bool primaryIsReal =
                            realDists.isNotEmpty &&
                            (importedDists.isEmpty ||
                                realDists.last >= importedDists.last);

                        int start = selectedIndexStart!;
                        int end = selectedIndexEnd!;

                        if (!primaryIsReal) {
                          start = mapIndexByDistance(
                            start,
                            importedDists,
                            realDists,
                          );
                          end = mapIndexByDistance(
                            end,
                            importedDists,
                            realDists,
                          );
                        } else {
                          start = mapIndexByDistance(
                            start,
                            realDists,
                            importedDists,
                          );
                          end = mapIndexByDistance(
                            end,
                            realDists,
                            importedDists,
                          );
                        }

                        return _buildSegmentStatsBar(
                          importedTrack.altitudes,
                          importedTrack.distances,
                          importedTrack.timestamps,
                          AppColors.primary,
                        );
                      },
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─────────────────────────────────────────────
          // 2) GRÀFIC
          // ─────────────────────────────────────────────
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, chartConstraints) {
                final width = chartConstraints.maxWidth;

                // ⬇️ Aquí deixes EXACTAMENT el teu codi del gràfic
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
                          selectedIndexEnd != null &&
                          selectedIndexStart! >= 0 &&
                          selectedIndexEnd! >= 0 &&
                          selectedIndexStart! < primaryAlts.length &&
                          selectedIndexEnd! < primaryAlts.length)
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

          const SizedBox(height: 10),

          // ─────────────────────────────────────────────
          // 3) LLEGENDA
          // ─────────────────────────────────────────────
          _buildLegend(hasImported),
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
