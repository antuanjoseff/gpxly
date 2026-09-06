// lib/notifiers/live_follow_stats_notifier.dart
//
// Estadístiques de velocitat, desnivell, distància i temps calculades EN VIU
// a partir del GPS mentre se segueix un track importat
// (navigationProvider.isFollowing), independentment de si s'està gravant.
//
// RIGOR ARQUITECTÒNIC:
//  - Aquest notifier és purament additiu: mai llegeix ni modifica
//    `trackRecordingProvider` (RecordingNotifier). No interfereix amb la
//    gravació real, el seu autosave ni la seva recuperació de cache.
//  - Reutilitza els mateixos algorismes que RecordingNotifier
//    (Track.computeSmoothedSpeeds, Track.computeMaxSustainedSpeed,
//    ElevationUtils.smooth/robustGain) per mantenir coherència numèrica amb
//    els valors que es mostren durant una gravació real.
//  - El buffer intern es reinicia cada vegada que comença una nova sessió
//    de seguiment (isFollowing false -> true), per no arrossegar dades
//    d'una sessió anterior.
//  - Si es grava i se segueix alhora, stats_screen ja mostra les dades del
//    track gravat (vegeu `useLiveStats` a stats_screen.dart), de manera que
//    el recàlcul de suavitzat aquí seria pur malbaratament de CPU: mentre
//    `isRecording` és cert, seguim acumulant punts (perquè el buffer no
//    tingui forats si la gravació s'atura) però NO recalculem les
//    estadístiques.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/helpers/thresholds.dart';
import 'package:strack_rec/utils/calculations.dart';
import 'package:strack_rec/utils/geo_utils.dart';

class LiveFollowStats {
  final double currentSpeedKmh;
  final double averageSpeedKmh;
  final double averageSpeedTotalKmh;
  final double maxSpeedKmh;
  final double ascent;
  final double descent;
  final double maxElevation;
  final double minElevation;
  final double? currentAltitude;
  final double distanceMeters;
  final Duration duration;
  final Duration stoppedDuration;
  final bool hasData;

  const LiveFollowStats({
    this.currentSpeedKmh = 0.0,
    this.averageSpeedKmh = 0.0,
    this.averageSpeedTotalKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.ascent = 0.0,
    this.descent = 0.0,
    this.maxElevation = -9999.0,
    this.minElevation = 9999.0,
    this.currentAltitude,
    this.distanceMeters = 0.0,
    this.duration = Duration.zero,
    this.stoppedDuration = Duration.zero,
    this.hasData = false,
  });

  Duration get movingDuration => duration - stoppedDuration;

  static const empty = LiveFollowStats();
}

class LiveFollowStatsNotifier extends Notifier<LiveFollowStats> {
  final List<double> _recentValidSpeeds = [];
  final List<_TimedSpeed> _recentSustainedSpeeds = [];
  final IncrementalElevationGain _elevationGain = IncrementalElevationGain();
  bool _wasFollowing = false;
  LiveFollowStats _lastComputed = LiveFollowStats.empty;
  UserPosition? _lastPoint;
  DateTime? _firstTimestamp;
  DateTime? _stopStartedAt;
  bool _isStopped = false;
  int _pointCount = 0;
  double _distanceMeters = 0.0;
  double _stoppedSeconds = 0.0;
  double _speedSum = 0.0;
  int _speedCount = 0;
  double _movingSpeedSum = 0.0;
  int _movingSpeedCount = 0;
  double _maxSpeedKmh = 0.0;
  double _maxElevation = -9999.0;
  double _minElevation = 9999.0;
  double? _lastValidSegmentSpeed;

  @override
  LiveFollowStats build() {
    final navState = ref.watch(navigationProvider);
    final position = ref.watch(locationProvider);
    final isRecording = ref.watch(
      trackRecordingProvider.select(
        (t) => t.recordingState == RecordingState.recording,
      ),
    );

    if (navState.isFollowing && !_wasFollowing) {
      _reset();
    }
    _wasFollowing = navState.isFollowing;

    if (!navState.isFollowing) {
      return LiveFollowStats.empty;
    }

    // En pausa no acumulem punts nous, però mantenim les últimes estadístiques.
    if (!navState.isPaused &&
        position != null &&
        position.timestamp != _lastPoint?.timestamp) {
      _addPosition(position);
    }

    if (isRecording) {
      return _lastComputed;
    }

    return _lastComputed;
  }

  void _addPosition(UserPosition point) {
    _pointCount += 1;
    _firstTimestamp ??= point.timestamp;

    final previousPoint = _lastPoint;
    if (previousPoint != null) {
      final step = distanceBetween(
        previousPoint.position.latitude,
        previousPoint.position.longitude,
        point.position.latitude,
        point.position.longitude,
      );
      if (step.isFinite && step < 200) {
        _distanceMeters += step;
      }
    }

    final currentSpeedKmh = _smoothedSpeedFor(point, previousPoint);
    _updateStoppedDuration(point);
    final gain = _elevationGain.add(point.altitude, _distanceMeters);

    _maxElevation = _pointCount == 1
        ? point.altitude
        : _maxElevation < point.altitude
        ? point.altitude
        : _maxElevation;
    _minElevation = _pointCount == 1
        ? point.altitude
        : _minElevation > point.altitude
        ? point.altitude
        : _minElevation;

    _speedSum += currentSpeedKmh;
    _speedCount += 1;
    if (currentSpeedKmh > 0.0) {
      _movingSpeedSum += currentSpeedKmh;
      _movingSpeedCount += 1;
    }
    _updateMaxSustainedSpeed(point.timestamp, currentSpeedKmh);
    _lastPoint = point;

    final duration = point.timestamp.difference(_firstTimestamp!);
    final stoppedDuration = Duration(
      milliseconds:
          ((_stoppedSeconds +
                      (_isStopped && _stopStartedAt != null
                          ? point.timestamp
                                    .difference(_stopStartedAt!)
                                    .inMilliseconds /
                                1000.0
                          : 0.0)) *
                  1000)
              .round(),
    );
    _lastComputed = LiveFollowStats(
      currentSpeedKmh: currentSpeedKmh,
      averageSpeedKmh: _movingSpeedCount == 0
          ? 0.0
          : _movingSpeedSum / _movingSpeedCount,
      averageSpeedTotalKmh: _speedSum / _speedCount,
      maxSpeedKmh: _maxSpeedKmh,
      ascent: gain.ascent,
      descent: gain.descent,
      maxElevation: _maxElevation,
      minElevation: _minElevation,
      currentAltitude: point.altitude,
      distanceMeters: _distanceMeters,
      duration: duration,
      stoppedDuration: stoppedDuration,
      hasData: true,
    );
  }

  double _smoothedSpeedFor(UserPosition point, UserPosition? previousPoint) {
    var segmentSpeedKmh = 0.0;
    if (previousPoint != null) {
      final accuracyLimit = _pointCount < Track.smoothedSpeedWindow
          ? Track.smoothedSpeedMinAccuracy
          : TrackThresholds.speedEstablishedMinAccuracyMeters;
      if (previousPoint.accuracy < accuracyLimit &&
          point.accuracy < accuracyLimit) {
        final elapsedSeconds =
            point.timestamp.difference(previousPoint.timestamp).inMilliseconds /
            1000.0;
        final meters = distanceBetween(
          previousPoint.position.latitude,
          previousPoint.position.longitude,
          point.position.latitude,
          point.position.longitude,
        );
        if (elapsedSeconds > 0.0 && meters.isFinite && meters > 0.0) {
          final candidateSpeed = (meters / elapsedSeconds) * 3.6;
          final maximumPlausibleSpeed = _lastValidSegmentSpeed == null
              ? double.infinity
              : _lastValidSegmentSpeed! +
                    TrackThresholds.speedMaxAccelerationKmhPerSecond *
                        elapsedSeconds;
          if (candidateSpeed <= maximumPlausibleSpeed) {
            segmentSpeedKmh = candidateSpeed;
            _lastValidSegmentSpeed = candidateSpeed;
          }
        }
      }
    }

    if (segmentSpeedKmh > 0.0 && segmentSpeedKmh.isFinite) {
      _recentValidSpeeds.add(segmentSpeedKmh);
      if (_recentValidSpeeds.length > Track.smoothedSpeedWindow) {
        _recentValidSpeeds.removeAt(0);
      }
    }
    if (_recentValidSpeeds.isEmpty) return 0.0;
    final sum = _recentValidSpeeds.fold<double>(
      0.0,
      (sum, speed) => sum + speed,
    );
    return sum / _recentValidSpeeds.length;
  }

  void _updateStoppedDuration(UserPosition point) {
    if (point.speed < 0.3) {
      if (!_isStopped) {
        _isStopped = true;
        _stopStartedAt = point.timestamp;
      }
    } else if (_isStopped && _stopStartedAt != null) {
      _stoppedSeconds +=
          point.timestamp.difference(_stopStartedAt!).inMilliseconds / 1000.0;
      _isStopped = false;
      _stopStartedAt = null;
    }
  }

  void _updateMaxSustainedSpeed(DateTime timestamp, double speedKmh) {
    _recentSustainedSpeeds.add(_TimedSpeed(timestamp, speedKmh));
    final windowStart = timestamp.subtract(
      const Duration(seconds: TrackThresholds.maxSustainedSpeedWindowSeconds),
    );
    var startIndex = -1;
    for (var index = _recentSustainedSpeeds.length - 1; index >= 0; index--) {
      if (!_recentSustainedSpeeds[index].timestamp.isAfter(windowStart)) {
        startIndex = index;
        break;
      }
    }

    if (startIndex >= 0) {
      var minimumSpeed = _recentSustainedSpeeds[startIndex].speedKmh;
      if (_recentSustainedSpeeds[startIndex].timestamp != windowStart) {
        final rightIndex = startIndex + 1;
        if (rightIndex < _recentSustainedSpeeds.length) {
          final left = _recentSustainedSpeeds[startIndex];
          final right = _recentSustainedSpeeds[rightIndex];
          final totalSeconds =
              right.timestamp.difference(left.timestamp).inMilliseconds /
              1000.0;
          if (totalSeconds > 0.0) {
            final elapsedSeconds =
                windowStart.difference(left.timestamp).inMilliseconds / 1000.0;
            minimumSpeed +=
                (right.speedKmh - minimumSpeed) * elapsedSeconds / totalSeconds;
          }
        }
      }
      for (
        var index = startIndex + 1;
        index < _recentSustainedSpeeds.length;
        index++
      ) {
        final candidateSpeed = _recentSustainedSpeeds[index].speedKmh;
        if (candidateSpeed < minimumSpeed) minimumSpeed = candidateSpeed;
      }
      if (minimumSpeed >= 0.0 && minimumSpeed > _maxSpeedKmh) {
        _maxSpeedKmh = minimumSpeed;
      }
    }

    while (_recentSustainedSpeeds.length > 1 &&
        !_recentSustainedSpeeds[1].timestamp.isAfter(windowStart)) {
      _recentSustainedSpeeds.removeAt(0);
    }
  }

  void _reset() {
    _recentValidSpeeds.clear();
    _recentSustainedSpeeds.clear();
    _elevationGain.reset();
    _lastComputed = LiveFollowStats.empty;
    _lastPoint = null;
    _firstTimestamp = null;
    _stopStartedAt = null;
    _isStopped = false;
    _pointCount = 0;
    _distanceMeters = 0.0;
    _stoppedSeconds = 0.0;
    _speedSum = 0.0;
    _speedCount = 0;
    _movingSpeedSum = 0.0;
    _movingSpeedCount = 0;
    _maxSpeedKmh = 0.0;
    _maxElevation = -9999.0;
    _minElevation = 9999.0;
    _lastValidSegmentSpeed = null;
  }
}

class _TimedSpeed {
  const _TimedSpeed(this.timestamp, this.speedKmh);

  final DateTime timestamp;
  final double speedKmh;
}

final liveFollowStatsProvider =
    NotifierProvider<LiveFollowStatsNotifier, LiveFollowStats>(
      LiveFollowStatsNotifier.new,
    );
