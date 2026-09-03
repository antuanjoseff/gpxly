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
    final track = isRecording && realTrack.points.isNotEmpty
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
            : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      ),
      'coords:1': _MapStat(
        t.mapStatPositionDms,
        position == null
            ? '--'
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
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
    final visible = selected.take(StatsPrefsNotifier.maxMapStats).toList();

    return Positioned(
      top: 10,
      left: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...visible.map(
            (entry) => _MapStatItem(
              id: entry.key,
              stat: entry.value,
              onDismiss: () => ref
                  .read(statsPrefsProvider.notifier)
                  .toggleMapStat(entry.key),
            ),
          ),
          if (selected.length > visible.length)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                '+${selected.length - visible.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapStat {
  const _MapStat(this.label, this.value) : widget = null;
  const _MapStat.widget(this.label, this.widget) : value = null;

  final String label;
  final String? value;
  final Widget? widget;
}

class _MapStatItem extends StatelessWidget {
  const _MapStatItem({
    required this.id,
    required this.stat,
    required this.onDismiss,
  });

  final String id;
  final _MapStat stat;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -200) {
          onDismiss();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        constraints: const BoxConstraints(maxWidth: 180),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(235),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(75)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stat.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            stat.widget ??
                Text(
                  stat.value ?? '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
