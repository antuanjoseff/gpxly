import 'package:gpxly/models/track.dart';
import 'package:gpxly/utils/map_layers.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapAnimator {
  final MapLibreMapController controller;

  LatLng? _lastUserPos;
  List<List<double>>? _lastTrack;

  MapAnimator(this.controller);

  void updateFromTrack(Track track) {
    _animateUserPosition(track.currentPosition);
    _animateTrackSegment(track.coordinates, track.recordingState);
    _updateFullTrack(track.coordinates);
  }

  void _animateUserPosition(LatLng? newPos) {
    if (newPos == null) return;

    if (_lastUserPos == null) {
      setUserLocationGeometry(controller, newPos.latitude, newPos.longitude);
      _lastUserPos = newPos;
      return;
    }

    final from = _lastUserPos!;
    final to = newPos;

    const steps = 10;
    const dt = Duration(milliseconds: 16);

    for (int i = 0; i <= steps; i++) {
      Future.delayed(dt * i, () {
        final t = i / steps;
        final lat = from.latitude + (to.latitude - from.latitude) * t;
        final lon = from.longitude + (to.longitude - from.longitude) * t;
        setUserLocationGeometry(controller, lat, lon);
      });
    }

    _lastUserPos = newPos;
  }

  void _animateTrackSegment(List<List<double>> coords, RecordingState state) {
    if (state != RecordingState.recording) return;
    if (coords.length < 2) return;

    final lastTwo = coords.sublist(coords.length - 2);

    setAnimatingSegmentGeometry(controller, lastTwo);

    const steps = 12;
    const dt = Duration(milliseconds: 20);

    for (int i = 0; i <= steps; i++) {
      Future.delayed(dt * i, () {
        final t = i / steps;
        final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;

        controller.setLayerProperties(
          "track_animating_layer",
          LineLayerProperties(
            lineOpacity: opacity,
            lineColor: "#FF0000",
            lineWidth: 4.0,
          ),
        );
      });
    }
  }

  void _updateFullTrack(List<List<double>> coords) {
    if (_lastTrack == coords) return;
    setTrackLineGeometry(controller, coords);
    _lastTrack = coords;
  }
}
