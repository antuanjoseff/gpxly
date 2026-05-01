import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gpxly/features/elevation_profile/painters/selection_painter.dart';
import 'package:gpxly/features/elevation_profile/painters/range_highlight_painter.dart';
import 'package:gpxly/features/elevation_profile/utils/chart_utils.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/models/waypoint.dart';
import 'package:gpxly/notifiers/imported_track_settings_notifier.dart';

import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/notifiers/waypoints_recorded_notifier.dart';
import 'package:gpxly/utils/distance_utils.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/waypoint_button.dart';

enum ActiveHandle { none, start, end }

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndexGraph;
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? expandedWaypointIndex;

  double statsHeight = 120;

  ActiveHandle activeHandle = ActiveHandle.none;
  int _draggingNeedle = 0;

  final chartKey = GlobalKey();

  final Color primaryNeedleColor = const Color(0xFF4CAF50);
  final Color secondaryNeedleColor = AppColors.mustardYellow;

  final Color sliderStartNeedleColor = const Color(0xFF4CAF50);
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
    Color trackColor,
    Color importedTrackColor,
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
          HorizontalLine(y: forcedMinY, color: Colors.grey, strokeWidth: 1.5),
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
        LineChartBarData(
          spots: List.generate(
            primaryAlts.length,
            (i) => FlSpot(primaryDists[i], primaryAlts[i]),
          ),
          isCurved: false,
          color: primaryIsReal ? trackColor : importedTrackColor,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: (primaryIsReal ? trackColor : AppColors.primary).withAlpha(
              primaryIsReal ? 64 : 32,
            ),
            cutOffY: forcedMinY,
            applyCutOffY: true,
          ),
        ),

        if (secondaryDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              secondaryAlts.length,
              (i) => FlSpot(secondaryDists[i], secondaryAlts[i]),
            ),
            isCurved: false,
            color: primaryIsReal ? trackColor : importedTrackColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (primaryIsReal ? trackColor : importedTrackColor)
                  .withAlpha(primaryIsReal ? 32 : 64),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  //  Segment Stats
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
    Color trackColor,
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
        color: trackColor,
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

  void _onShowWaypoint(Waypoint wp) {
    setState(() {
      selectedIndexGraph = (selectedIndexGraph == wp.trackIndex)
          ? null
          : wp.trackIndex;
    });
  }

  void _onSetStartFromWaypoint(Waypoint wp) {
    setState(() {
      selectedIndexStart = (selectedIndexStart == wp.trackIndex)
          ? null
          : wp.trackIndex;
      selectedIndexGraph = wp.trackIndex;
    });
  }

  void _onSetEndFromWaypoint(Waypoint wp) {
    setState(() {
      selectedIndexEnd = (selectedIndexEnd == wp.trackIndex)
          ? null
          : wp.trackIndex;
      selectedIndexGraph = wp.trackIndex;
    });
  }

  // 1) Substitueix el teu _buildWaypointsList per aquest:
  Widget _buildWaypointsList(BuildContext context) {
    final waypoints = ref.watch(waypointsProvider);

    if (waypoints.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 44,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: waypoints.length,
      itemBuilder: (_, i) {
        final wp = waypoints[i];

        return Container(
          padding: const EdgeInsets.only(left: 10, right: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ahora el nombre empieza directamente y tiene más espacio
              Expanded(
                child: Text(
                  wp.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Botones grandes y ultra-compactos
              _compactActionBtn(
                icon: Icons.visibility,
                active: selectedIndexGraph == wp.trackIndex,
                activeColor: AppColors.skyBlue,
                onTap: () => _onShowWaypoint(wp),
              ),
              _compactActionBtn(
                icon: Icons.flag_circle,
                active: selectedIndexStart == wp.trackIndex,
                activeColor: AppColors.trackGreen,
                onTap: () => _onSetStartFromWaypoint(wp),
              ),
              _compactActionBtn(
                icon: Icons.flag,
                active: selectedIndexEnd == wp.trackIndex,
                activeColor: AppColors.redAlert,
                onTap: () => _onSetEndFromWaypoint(wp),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _compactActionBtn({
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return IconButton(
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
      icon: Icon(icon, color: active ? activeColor : Colors.black26),
      onPressed: onTap,
    );
  }

  // ------------------------------------------------------------
  //  BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);

    final realAlts = real.altitudes;
    final realDists = calculateDistances(real.coordinates);

    final importedAlts = imported?.altitudes ?? <double>[];
    final importedDists = calculateDistances(imported?.coordinates ?? []);

    final hasReal = realAlts.isNotEmpty;
    final hasImported = importedAlts.isNotEmpty;

    if (!hasReal && !hasImported) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(t.elevationProfile),
        ),
        body: Center(child: Text(t.noData)),
      );
    }

    final bool primaryIsReal =
        realDists.isNotEmpty &&
        (importedDists.isEmpty || realDists.last >= importedDists.last);

    final primaryAlts = primaryIsReal ? realAlts : importedAlts;
    final primaryDists = primaryIsReal ? realDists : importedDists;

    final secondaryAlts = primaryIsReal ? importedAlts : realAlts;
    final secondaryDists = primaryIsReal ? importedDists : realDists;

    final chartHeight = MediaQuery.of(context).size.height * 0.3;
    final importedTrack = ref.watch(importedTrackProvider);

    final track = ref.watch(trackProvider);
    final trackSettings = ref.watch(trackSettingsProvider);
    final Color trackColor = trackSettings.color;

    final importedTrackSettings = ref.watch(importedTrackSettingsProvider);
    final importedTrackColor = importedTrackSettings.color;

    return Scaffold(
      appBar: AppBar(title: Text(t.elevationProfile)),
      body: Column(
        children: [
          SizedBox(height: 20),

          // ─────────────────────────────────────────────
          // 1) BLOC D’ESTADÍSTIQUES AMB ALÇADA FIXA
          // ─────────────────────────────────────────────
          SizedBox(
            height: 135,
            child: Column(
              children: [
                if (selectedIndexStart != null && selectedIndexEnd != null) ...[
                  if (track.distances.isNotEmpty)
                    _buildSegmentStatsBar(
                      track.altitudes,
                      track.distances,
                      track.timestamps,
                      trackColor,
                    ),

                  const SizedBox(height: 8),

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
                              trackColor,
                              importedTrackColor,
                            ),
                          ),
                        ),
                      ),

                      // Agulles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SelectionPainter(
                            waypointIndices: ref
                                .watch(waypointsProvider)
                                .map((wp) => wp.trackIndex)
                                .toList(),

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
          _buildLegend(
            hasReal: real.coordinates.isNotEmpty,
            hasImported: importedTrack?.coordinates.isNotEmpty ?? false,
            primaryIsReal: primaryIsReal,
            trackColor: trackColor,
            importedTrackColor: importedTrackColor,
          ),

          Expanded(child: _buildWaypointsList(context)),
        ],
      ),
    );
  }
}

Widget _buildLegend({
  required bool hasReal,
  required bool hasImported,
  required bool primaryIsReal,
  required Color trackColor,
  required Color importedTrackColor,
}) {
  if (!hasReal && !hasImported) {
    return const SizedBox.shrink();
  }

  final effectivePrimaryIsReal = hasReal ? primaryIsReal : false;

  final primaryLabel = effectivePrimaryIsReal ? "Track real" : "Track importat";
  final secondaryLabel = effectivePrimaryIsReal
      ? "Track importat"
      : "Track real";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        // PRIMER TRACK (només si existeix)
        if (hasReal || hasImported)
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: effectivePrimaryIsReal
                      ? trackColor
                      : importedTrackColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),

        const SizedBox(width: 20),

        // SEGON TRACK (només si existeix)
        if (hasReal && hasImported)
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: effectivePrimaryIsReal
                      ? importedTrackColor
                      : trackColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                secondaryLabel,
                style: const TextStyle(
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
