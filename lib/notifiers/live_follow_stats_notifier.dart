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
  final List<UserPosition> _buffer = [];
  bool _wasFollowing = false;
  LiveFollowStats _lastComputed = LiveFollowStats.empty;

  @override
  LiveFollowStats build() {
    final navState = ref.watch(navigationProvider);
    final position = ref.watch(locationProvider);
    final isRecording = ref.watch(
      trackRecordingProvider.select(
        (t) => t.recordingState == RecordingState.recording,
      ),
    );

    // Nova sessió de seguiment: netegem el buffer per no arrossegar dades
    // d'una sessió anterior (track diferent o seguiment reiniciat).
    if (navState.isFollowing && !_wasFollowing) {
      _buffer.clear();
      _lastComputed = LiveFollowStats.empty;
    }
    _wasFollowing = navState.isFollowing;

    if (!navState.isFollowing) {
      return LiveFollowStats.empty;
    }

    // En pausa no acumulem punts nous, però mantenim les últimes estadístiques.
    if (!navState.isPaused && position != null) {
      _buffer.add(position);
    }

    // Gravant: stats_screen no consumeix aquest resultat (fa servir el track
    // gravat). Evitem el recàlcul O(n) de suavitzat/desnivell a cada punt GPS
    // i retornem l'última estadística vàlida sense tornar-la a computar.
    if (isRecording) {
      return _lastComputed;
    }

    _lastComputed = _computeStats();
    return _lastComputed;
  }

  LiveFollowStats _computeStats() {
    if (_buffer.length < 2) {
      final last = _buffer.isNotEmpty ? _buffer.last : null;
      return LiveFollowStats(
        currentAltitude: last?.altitude,
        hasData: _buffer.isNotEmpty,
      );
    }

    final smoothedSpeeds = Track.computeSmoothedSpeeds(_buffer);

    double currentSpeedKmh = smoothedSpeeds.isNotEmpty
        ? smoothedSpeeds.last
        : 0.0;
    // Mateix filtre protector que RecordingNotifier per a salts absurds.
    if (currentSpeedKmh.isNegative || currentSpeedKmh > 130.0) {
      currentSpeedKmh = 0.0;
    }

    final double averageSpeedKmh = Track.averageSmoothedSpeed(
      smoothedSpeeds,
      includeZero: false,
    );
    final double averageSpeedTotalKmh = Track.averageSmoothedSpeed(
      smoothedSpeeds,
      includeZero: true,
    );
    final double maxSpeedKmh = Track.computeMaxSustainedSpeed(
      _buffer,
      smoothedSpeeds,
    );

    final List<double> alts = _buffer.map((p) => p.altitude).toList();
    final smoothAlts = ElevationUtils.smooth(alts);
    final gain = ElevationUtils.robustGain(smoothAlts);

    double maxElevation = alts.first;
    double minElevation = alts.first;
    for (final a in alts) {
      if (a > maxElevation) maxElevation = a;
      if (a < minElevation) minElevation = a;
    }

    final (distanceMeters, duration, stoppedDuration) =
        _computeDistanceAndTime();

    return LiveFollowStats(
      currentSpeedKmh: currentSpeedKmh,
      averageSpeedKmh: averageSpeedKmh,
      averageSpeedTotalKmh: averageSpeedTotalKmh,
      maxSpeedKmh: maxSpeedKmh,
      ascent: gain['ascent'] ?? 0.0,
      descent: gain['descent'] ?? 0.0,
      maxElevation: maxElevation,
      minElevation: minElevation,
      currentAltitude: _buffer.last.altitude,
      distanceMeters: distanceMeters,
      duration: duration,
      stoppedDuration: stoppedDuration,
      hasData: true,
    );
  }

  /// Distància acumulada i temps (total/aturat) recalculats en un únic pas
  /// sobre el buffer complet. Mateix filtre de salt GPS (<200m per pas) i
  /// mateix llindar d'aturada (<0.3 m/s) que fa servir RecordingNotifier.
  (double, Duration, Duration) _computeDistanceAndTime() {
    double distance = 0.0;
    Duration stopped = Duration.zero;

    bool isStopped = false;
    DateTime? stopStart;

    for (int i = 0; i < _buffer.length; i++) {
      final point = _buffer[i];

      if (i > 0) {
        final prev = _buffer[i - 1];
        final step = distanceBetween(
          prev.position.latitude,
          prev.position.longitude,
          point.position.latitude,
          point.position.longitude,
        );
        if (step.isFinite && step < 200) {
          distance += step;
        }
      }

      if (point.speed < 0.3) {
        if (!isStopped) {
          stopStart = point.timestamp;
          isStopped = true;
        }
      } else if (isStopped && stopStart != null) {
        stopped += point.timestamp.difference(stopStart);
        isStopped = false;
        stopStart = null;
      }
    }
    if (isStopped && stopStart != null) {
      stopped += _buffer.last.timestamp.difference(stopStart);
    }

    final duration = _buffer.last.timestamp.difference(_buffer.first.timestamp);
    return (distance, duration, stopped);
  }
}

final liveFollowStatsProvider =
    NotifierProvider<LiveFollowStatsNotifier, LiveFollowStats>(
      LiveFollowStatsNotifier.new,
    );
