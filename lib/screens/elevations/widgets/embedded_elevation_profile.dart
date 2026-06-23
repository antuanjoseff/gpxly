import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/screens/elevations/widgets/elevation_chart_widget.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/theme/app_dimensions.dart';
import 'package:senda/utils/distance_utils.dart';

class EmbeddedElevationProfile extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const EmbeddedElevationProfile({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  ConsumerState<EmbeddedElevationProfile> createState() =>
      _EmbeddedElevationProfileState();
}

class _EmbeddedElevationProfileState
    extends ConsumerState<EmbeddedElevationProfile> {
  final ValueNotifier<int?> _localHoverIndex = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeStart = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeEnd = ValueNotifier<int?>(null);
  final DateTime _lastTouchMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _touchThrottleDurationMs = 32;
  List<double> _cachedImportedDists = [];
  int _lastCoordinatesLength = 0;

  @override
  void dispose() {
    _localHoverIndex.dispose();
    _localRangeStart.dispose();
    _localRangeEnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);
    final follow = ref.watch(navigationProvider);

    final selectionState = ref.watch(elevationSelectionProvider);
    final bool isRangeActive = selectionState.mode == SelectionMode.range;

    final realAlts = real.altitudes;
    final realDists = real.distances;
    final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
    final bool shouldShowFuture =
        follow.isFollowing && !follow.isOffTrack && remaining != null;

    if (realAlts.isEmpty && (imported == null || imported.altitudes.isEmpty)) {
      return const SizedBox.shrink();
    }

    late List<double> futureAlts;
    late List<double> futureDistsGlobal;
    List<DateTime> futureTimestamps = [];

    if (shouldShowFuture) {
      final double maxFutureDistanceVisible = pastLastDist / 3.0;
      final remainingAlts = remaining.altitudes;
      final remainingDists = remaining.distances;
      double elevationOffset = 0.0;
      if (realAlts.isNotEmpty && remainingAlts.isNotEmpty) {
        elevationOffset = realAlts.last - remainingAlts.first;
      }
      final List<double> tempFutureAlts = [];
      final List<double> tempFutureDists = [];
      for (int i = 0; i < remainingDists.length; i++) {
        if (remainingDists[i] <= maxFutureDistanceVisible) {
          tempFutureAlts.add(remainingAlts[i] + elevationOffset);
          tempFutureDists.add(pastLastDist + remainingDists[i]);
        } else {
          break;
        }
      }
      futureAlts = tempFutureAlts;
      futureDistsGlobal = tempFutureDists;
    } else {
      if (imported != null && imported.coordinates.isNotEmpty) {
        if (_lastCoordinatesLength != imported.coordinates.length) {
          _lastCoordinatesLength = imported.coordinates.length;
          _cachedImportedDists = calculateDistances(imported.coordinates);
        }
        futureDistsGlobal = _cachedImportedDists;
      } else {
        _lastCoordinatesLength = 0;
        _cachedImportedDists = [];
        futureDistsGlobal = [];
      }
      futureAlts = imported?.altitudes ?? [];
      futureTimestamps = imported?.timestamps ?? [];
    }

    final globalDists = <double>[...realDists, ...futureDistsGlobal];
    final globalAlts = <double>[...realAlts, ...futureAlts];
    final globalTimes = <DateTime>[...real.timestamps, ...futureTimestamps];
    double rangeDistance = 0;
    double rangeAscent = 0;
    double rangeDescent = 0;

    String timeElapsedStr = "--:--";
    String avgSpeedStr = "--.- km/h";

    // 🔥 1) Primer intentem calcular TRAM seleccionat
    bool hasRange = false;

    if (isRangeActive &&
        selectionState.startTrackIndex != null &&
        selectionState.endTrackIndex != null) {
      final int start = selectionState.startTrackIndex!;
      final int end = selectionState.endTrackIndex!;

      if (start < globalDists.length && end < globalDists.length) {
        hasRange = true;

        rangeDistance = (globalDists[end] - globalDists[start]).abs();

        final int startIdx = start < end ? start : end;
        final int endIdx = start < end ? end : start;

        for (int i = startIdx + 1; i <= endIdx; i++) {
          if (i >= globalAlts.length) break;
          final diff = globalAlts[i] - globalAlts[i - 1];
          if (diff > 0) rangeAscent += diff;
          if (diff < 0) rangeDescent += diff.abs();
        }

        if (startIdx < globalTimes.length && endIdx < globalTimes.length) {
          final duration = globalTimes[endIdx]
              .difference(globalTimes[startIdx])
              .abs();

          final int totalHours = duration.inHours;
          final int totalMinutes = duration.inMinutes.remainder(60);
          final int totalSeconds = duration.inSeconds.remainder(60);

          if (totalHours > 0) {
            timeElapsedStr =
                "${totalHours}h ${totalMinutes.toString().padLeft(2, '0')}m";
          } else {
            timeElapsedStr =
                "$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}";
          }

          if (duration.inSeconds > 0 && rangeDistance > 0) {
            final double speedMps = rangeDistance / duration.inSeconds;
            final double speedKmh = speedMps * 3.6;
            avgSpeedStr = "${speedKmh.toStringAsFixed(1)} km/h";
          }
        }
      }
    }

    // 🔥 2) Si NO hi ha tram → calculem TOT EL TRACK
    if (!hasRange) {
      final int start = 0;
      final int end = globalDists.length - 1;

      if (end > start) {
        rangeDistance = (globalDists[end] - globalDists[start]).abs();

        for (int i = start + 1; i <= end; i++) {
          final diff = globalAlts[i] - globalAlts[i - 1];
          if (diff > 0) rangeAscent += diff;
          if (diff < 0) rangeDescent += diff.abs();
        }

        if (start < globalTimes.length && end < globalTimes.length) {
          final duration = globalTimes[end]
              .difference(globalTimes[start])
              .abs();

          final int totalHours = duration.inHours;
          final int totalMinutes = duration.inMinutes.remainder(60);
          final int totalSeconds = duration.inSeconds.remainder(60);

          if (totalHours > 0) {
            timeElapsedStr =
                "${totalHours}h ${totalMinutes.toString().padLeft(2, '0')}m";
          } else {
            timeElapsedStr =
                "$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}";
          }

          if (duration.inSeconds > 0 && rangeDistance > 0) {
            final double speedMps = rangeDistance / duration.inSeconds;
            final double speedKmh = speedMps * 3.6;
            avgSpeedStr = "${speedKmh.toStringAsFixed(1)} km/h";
          }
        }
      }
    }

    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);
    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedTrackColor = ref.watch(importedTrackSettingsProvider).color;

    final recordedWaypointGlobalDists = recordedWps
        .where((wp) => wp.trackIndex >= 0 && wp.trackIndex < realDists.length)
        .map((wp) => realDists[wp.trackIndex])
        .toList(growable: false);

    final importedWaypointGlobalDists = <double>[];
    if (!shouldShowFuture) {
      for (final wp in importedWps) {
        if (wp.trackIndex < futureDistsGlobal.length) {
          importedWaypointGlobalDists.add(futureDistsGlobal[wp.trackIndex]);
        }
      }
    } else {
      for (final wp in importedWps) {
        final idx = wp.trackIndex;
        if (idx < remaining.anchorIndex) continue;
        final futureIdx = idx - remaining.anchorIndex;
        if (futureIdx < remaining.distances.length) {
          importedWaypointGlobalDists.add(
            pastLastDist + remaining.distances[futureIdx],
          );
        }
      }
    }

    final String safeSpeedStr = avgSpeedStr.replaceAll(" km/h", "kmh");

    final double screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight =
        (screenHeight * AppDimensions.elevationChartHeightRatio)
            .roundToDouble();
    const double handleHeight = 36.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Àrea del gràfic
        if (!widget.isCollapsed)
          Expanded(
            child: SizedBox(
              height: chartHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _localHoverIndex,
                  _localRangeStart,
                  _localRangeEnd,
                ]),
                builder: (context, _) {
                  return ElevationChartWidget(
                    key: const ValueKey("elevation_chart_embedded_pure"),
                    pastAlts: realAlts,
                    pastDists: realDists,
                    futureAlts: futureAlts,
                    futureDistsGlobal: futureDistsGlobal,
                    recordedWaypointGlobalDists: recordedWaypointGlobalDists,
                    importedWaypointGlobalDists: importedWaypointGlobalDists,
                    realColor: trackColor,
                    importedColor: importedTrackColor,
                    graphNeedleColor: AppColors.primary,
                    sliderStartNeedleColor: Colors.green,
                    sliderEndNeedleColor: Colors.red,
                  );
                },
              ),
            ),
          ),
        // Barra d’estadístiques del tram
        if (!widget.isCollapsed)
          SizedBox(
            height: handleHeight,
            child: GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: handleHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.dark.withAlpha(150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "${(rangeDistance / 1000).toStringAsFixed(2)}km",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeElapsedStr,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.speed_rounded,
                                  size: 12,
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  safeSpeedStr,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 12,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "+${rangeAscent.toStringAsFixed(0)}m",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  size: 12,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "-${rangeDescent.toStringAsFixed(0)}m",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
