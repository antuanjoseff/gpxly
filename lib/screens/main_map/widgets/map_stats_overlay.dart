import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/live_follow_stats_notifier.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/waypoint_eta_notifier.dart';
import 'package:strack_rec/providers/barometer_provider.dart';
import 'package:strack_rec/screens/stats/notifiers/stats_prefs_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/utils/calculations.dart';
import 'package:strack_rec/widgets/gps_accuracy_bars.dart';

class MapStatsOverlay extends ConsumerWidget {
  const MapStatsOverlay({super.key});

  String _duration(Duration value) =>
      value.toString().split('.').first.padLeft(8, '0');

  String _pace(double speedKmh) {
    if (speedKmh <= 0.3) return '--:--';
    final totalSeconds = (3600 / speedKmh).round();
    return '${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _distance(double? km) {
    if (km == null) return '--';
    final meters = (km * 1000).round();
    return meters % 1000 == 0
        ? '${meters ~/ 1000} km'
        : '${meters ~/ 1000}km ${meters % 1000}m';
  }

  String _coordinateDms(double coordinate, bool isLatitude) {
    final direction = isLatitude
        ? (coordinate >= 0 ? 'N' : 'S')
        : (coordinate >= 0 ? 'E' : 'O');
    final totalSeconds = (coordinate.abs() * 3600).round();
    final degrees = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '$degrees°$minutes\'$seconds"$direction';
  }

  (double, double) _gain(dynamic track) {
    if (track == null || track.altitudes.length < 2) return (0, 0);
    final gain = ElevationUtils.computeGain(
      (track.altitudes as List).cast<double>(),
      distances: (track.distances as List).cast<double>(),
    );
    return (gain.ascent, gain.descent);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final prefs = ref.watch(statsPrefsProvider);
    if (!prefs.isInitialized || prefs.mapStatIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final realTrack = ref.watch(trackRecordingProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final isRecording = realTrack.recordingState == RecordingState.recording;
    final track = isRecording
        ? realTrack
        : (importedTrack != null && importedTrack.points.isNotEmpty
              ? importedTrack
              : (realTrack.points.isNotEmpty ? realTrack : null));
    final isFollowing = ref.watch(navigationProvider).isFollowing;
    final liveStats = ref.watch(liveFollowStatsProvider);
    final useLive = isFollowing && !isRecording && liveStats.hasData;
    final location = ref.watch(locationProvider);
    final nav = ref.watch(waypointEtaProvider);
    final (ascent, descent) = useLive
        ? (liveStats.ascent, liveStats.descent)
        : _gain(track);
    final duration = useLive
        ? liveStats.duration
        : track?.stats.duration ?? Duration.zero;
    final stopped = useLive
        ? liveStats.stoppedDuration
        : track?.stats.stoppedDuration ?? Duration.zero;
    final distance = useLive
        ? liveStats.distanceMeters / 1000
        : track == null
        ? null
        : track.distance / 1000;
    final speed = useLive
        ? liveStats.currentSpeedKmh
        : (realTrack.points.isNotEmpty
                  ? realTrack.currentSpeedKmH
                  : track?.currentSpeedKmH) ??
              0;
    final altitude = useLive
        ? liveStats.currentAltitude
        : track != null && track.altitudes.isNotEmpty
        ? track.altitudes.last
        : null;
    final remaining =
        isFollowing && importedTrack != null && importedTrack.points.isNotEmpty
        ? math.max(
                0,
                importedTrack.points.last.distanceAtPoint -
                    nav.currentTrackDistance,
              ) /
              1000
        : null;
    final position = track?.currentPosition ?? location?.position;

    final values = <String, _MapStat>{
      'dist:0': _MapStat(t.mapStatDistance, _distance(distance)),
      if (remaining != null)
        'dist:1': _MapStat(t.mapStatRemaining, _distance(remaining)),
      'time:0': _MapStat(t.mapStatTime, _duration(duration)),
      'time:1': _MapStat(t.mapStatMoving, _duration(duration - stopped)),
      'time:2': _MapStat(t.mapStatStopped, _duration(stopped)),
      'time:3': _MapStat(
        t.mapStatWaypoint,
        nav.eta == null ? '--:--' : _duration(nav.eta!),
      ),
      'speed:0': _MapStat(
        t.mapStatSpeed,
        '${speed < 0.4 ? '0.0' : speed.toStringAsFixed(1)} km/h',
      ),
      'speed:1': _MapStat(
        t.mapStatSpeedAvg,
        '${(useLive ? liveStats.averageSpeedKmh : track?.stats.averageSpeed)?.toStringAsFixed(1) ?? '--'} km/h',
      ),
      'speed:2': _MapStat(
        t.mapStatSpeedTotal,
        '${(useLive ? liveStats.averageSpeedTotalKmh : track?.stats.averageSpeedTotal)?.toStringAsFixed(1) ?? '--'} km/h',
      ),
      'speed:3': _MapStat(
        t.mapStatSpeedMax,
        '${(useLive ? liveStats.maxSpeedKmh : track?.stats.maxSpeed)?.toStringAsFixed(1) ?? '--'} km/h',
      ),
      'speed:4': _MapStat(t.mapStatPace, '${_pace(speed)} /km'),
      'speed:5': _MapStat(
        t.mapStatPaceAvg,
        '${_pace(useLive ? liveStats.averageSpeedKmh : track?.stats.averageSpeed ?? 0)} /km',
      ),
      'alt:0': _MapStat(
        t.mapStatAltitude,
        '${altitude?.toStringAsFixed(0) ?? '--'} m',
      ),
      'alt:1': _MapStat(
        t.mapStatAltMax,
        '${(useLive ? liveStats.maxElevation : track?.stats.maxElevation)?.toStringAsFixed(0) ?? '--'} m',
      ),
      'alt:2': _MapStat(
        t.mapStatAltMin,
        '${(useLive ? liveStats.minElevation : track?.stats.minElevation)?.toStringAsFixed(0) ?? '--'} m',
      ),
      'alt:3': _MapStat(t.mapStatAscent, '+${ascent.toStringAsFixed(0)} m'),
      'alt:4': _MapStat(t.mapStatDescent, '-${descent.toStringAsFixed(0)} m'),
      'coords:0': _MapStat(
        t.mapStatPosition,
        position == null
            ? '--'
            : '${position.latitude.toStringAsFixed(5)}°\n${position.longitude.toStringAsFixed(5)}°',
        isMultiline: true,
      ),
      'coords:1': _MapStat(
        t.mapStatPositionDms,
        position == null
            ? '--'
            : '${_coordinateDms(position.latitude, true)}\n${_coordinateDms(position.longitude, false)}',
        isMultiline: true,
      ),
      'gps:0': _MapStat(
        t.mapStatPressure,
        '${ref.watch(barometerProvider).value?.toStringAsFixed(0) ?? '--'} hPa',
      ),
      'gps:1': _MapStat(
        t.mapStatGps,
        '${location?.satellitesUsed ?? 0}/${location?.satellitesInView ?? 0}',
      ),
      'gps:2': _MapStat.widget(t.mapStatGpsAccuracy, const GpsAccuracyBars()),
    };
    final selected = prefs.mapStatIds
        .where(values.containsKey)
        .map((id) => MapEntry(id, values[id]!))
        .toList();
    if (selected.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 10,
      left: 12,
      child: _MapStatsCarousel(selected: selected),
    );
  }
}

class _MapStat {
  const _MapStat(this.label, this.value, {this.isMultiline = false})
    : widget = null;
  const _MapStat.widget(this.label, this.widget)
    : value = null,
      isMultiline = false;

  final String label;
  final String? value;
  final Widget? widget;
  final bool isMultiline;
}

class _MapStatsCarousel extends ConsumerStatefulWidget {
  const _MapStatsCarousel({required this.selected});

  final List<MapEntry<String, _MapStat>> selected;

  @override
  ConsumerState<_MapStatsCarousel> createState() => _MapStatsCarouselState();
}

class _MapStatsCarouselState extends ConsumerState<_MapStatsCarousel> {
  late final PageController _controller;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant _MapStatsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastPage = widget.selected.length - 1;
    if (_currentPage > lastPage) {
      _currentPage = lastPage;
      _controller.jumpToPage(_currentPage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsCardSize = (MediaQuery.sizeOf(context).width - 36) / 2;
    final carouselSize = statsCardSize * 0.75;

    return SizedBox(
      width: carouselSize,
      height: carouselSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.selected.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final entry = widget.selected[index];
                return _MapStatItem(stat: entry.value);
              },
            ),
            if (widget.selected.length > 1)
              Positioned(
                bottom: 6,
                left: 8,
                right: 8,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.selected.length, (
                          index,
                        ) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: isActive ? 9 : 4,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 1,
              right: 1,
              child: IconButton(
                tooltip: 'Treure del mapa',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                color: Colors.white70,
                onPressed: () => ref
                    .read(statsPrefsProvider.notifier)
                    .toggleMapStat(widget.selected[_currentPage].key),
                icon: const Icon(Icons.cancel_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStatItem extends StatelessWidget {
  const _MapStatItem({required this.stat});

  final _MapStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.dark.withAlpha(150),
        border: Border.all(color: Colors.white.withAlpha(75)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: stat.isMultiline
          ? _MapMultilineStat(stat: stat)
          : _MapSingleLineStat(stat: stat),
    );
  }
}

class _MapMultilineStat extends StatelessWidget {
  const _MapMultilineStat({required this.stat});

  final _MapStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stat.value ?? '--',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapSingleLineStat extends StatelessWidget {
  const _MapSingleLineStat({required this.stat});

  final _MapStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  stat.widget ??
                  Text(
                    stat.value ?? '--',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
