import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track_follow_state.dart';
import 'package:gpxly/utils/geo_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';

class TrackFollowNotifier extends Notifier<TrackFollowState> {
  List<LatLng> _importedTrack = [];
  StreamSubscription? _locationSub;

  // Història de distàncies per detectar tendència
  final List<double> _lastDistances = [];

  // Control de temps fora del track
  DateTime? _offTrackStart;

  static const double nearThreshold = 20; // torna al track
  static const double farThreshold = 35; // possible desviació
  static const int trendWindow = 6; // últims punts
  static const Duration offTrackDelay = Duration(seconds: 5);

  @override
  TrackFollowState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
    });

    return const TrackFollowState(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
    );
  }

  void toggleFollowing(BuildContext context) {
    if (state.isFollowing) {
      stopFollowing();
    } else {
      startFollowingWithRecording(context);
    }
  }

  void setImportedTrack(List<LatLng> coords) {
    _importedTrack = coords;
  }

  void startFollowingWithRecording(BuildContext context) async {
    // (el teu codi actual de permisos i gravació)
    // ...
    state = state.copyWith(isFollowing: true);
  }

  void stopFollowing() {
    state = state.copyWith(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
    );

    _lastDistances.clear();
    _offTrackStart = null;
  }

  // ------------------------------------------------------------
  // Actualitzar posició de l’usuari
  // ------------------------------------------------------------
  void updateUserPosition(LatLng userPos) {
    if (!state.isFollowing || _importedTrack.isEmpty) return;

    final closest = _closestPointAndSegment(userPos, _importedTrack);
    final dist = closest.distance;
    final trackBearing = closest.bearing;
    final userBearing = closest.userBearing;

    _lastDistances.add(dist);
    if (_lastDistances.length > trendWindow) {
      _lastDistances.removeAt(0);
    }

    final isTrendingAway = _isTrendingAway();
    final headingDiff = _headingDifference(trackBearing, userBearing);
    final isHeadingWrong = headingDiff > 45;

    final isFar = dist > farThreshold;
    final isNear = dist < nearThreshold;

    final wasOffTrack = state.isOffTrack;
    bool offTrack = state.isOffTrack;

    if (isFar && isTrendingAway && isHeadingWrong) {
      _offTrackStart ??= DateTime.now();

      if (DateTime.now().difference(_offTrackStart!) > offTrackDelay) {
        offTrack = true;
      }
    } else {
      _offTrackStart = null;
      if (isNear) offTrack = false;
    }

    if (!wasOffTrack && offTrack) {
      HapticFeedback.mediumImpact();
    }

    state = state.copyWith(distanceToTrack: dist, isOffTrack: offTrack);
  }

  // ------------------------------------------------------------
  // Distància + bearing del segment més proper
  // ------------------------------------------------------------
  _ClosestResult _closestPointAndSegment(LatLng p, List<LatLng> track) {
    double minDist = double.infinity;
    double segmentBearing = 0;
    double userBearing = 0;

    for (int i = 0; i < track.length - 1; i++) {
      final a = track[i];
      final b = track[i + 1];

      final d = distanceBetween(
        p.latitude,
        p.longitude,
        a.latitude,
        a.longitude,
      );

      if (d < minDist) {
        minDist = d;
        segmentBearing = bearingBetween(a, b);
        userBearing = bearingBetween(a, p);
      }
    }

    return _ClosestResult(
      distance: minDist,
      bearing: segmentBearing,
      userBearing: userBearing,
    );
  }

  // ------------------------------------------------------------
  // Tendència creixent
  // ------------------------------------------------------------
  bool _isTrendingAway() {
    if (_lastDistances.length < trendWindow) return false;

    for (int i = 1; i < _lastDistances.length; i++) {
      if (_lastDistances[i] < _lastDistances[i - 1]) {
        return false; // no és creixent
      }
    }
    return true;
  }

  // ------------------------------------------------------------
  // Diferència de heading (0–180)
  // ------------------------------------------------------------
  double _headingDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}

class _ClosestResult {
  final double distance;
  final double bearing;
  final double userBearing;

  _ClosestResult({
    required this.distance,
    required this.bearing,
    required this.userBearing,
  });
}

final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
