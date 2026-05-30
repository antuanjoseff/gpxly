// lib/utils/map_animator.dart
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/utils/map_layers.dart';

class MapAnimator {
  final MapLibreMapController controller;

  LatLng? _lastUserPos;
  List<List<double>>? _lastTrack;
  List<List<double>>? _lastAnimatedSegment;

  MapAnimator(this.controller);

  // ─────────────────────────────────────────────────────────────
  // 🛰️ ANIMACIÓ DE GLIDE DEL CERCLE BLAU (60 FPS Reals)
  // ─────────────────────────────────────────────────────────────
  // Esborrat 'updateUserPositionDirect' per evitar el salt inicial destructiu
  void animateUserPosition(LatLng? newPos) {
    if (newPos == null) return;

    if (_lastUserPos == null) {
      setUserLocationGeometry(controller, newPos.latitude, newPos.longitude);
      _lastUserPos = newPos;
      return;
    }

    final from = _lastUserPos!;
    final to = newPos;

    const steps =
        15; // Augmentat de 10 a 15 per fer la transició de lliscament més suau
    const dt = Duration(milliseconds: 16); // 16ms = ~60 ràfegues per segon

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

  // ─────────────────────────────────────────────────────────────
  // 📊 ANIMACIÓ DEL CREIXEMENT I POLS DE LA RUTA ENREGISTRADA
  // ─────────────────────────────────────────────────────────────
  void updateFromTrack(Track track) {
    // 1. L'animació del cercle blau es llegeix ara de forma controlada des d'oient A,
    // per tant enfoquem aquest mètode exclusivament a fer créixer la línia vermella.
    _animateTrackSegment(track.coordinates, track.recordingState);
  }

  void _animateTrackSegment(List<List<double>> coords, RecordingState state) {
    if (state != RecordingState.recording) {
      // Si estem en pausa o Stop, simplement dibuixem el traçat fix tancat
      _updateFullTrack(coords);
      return;
    }
    if (coords.length < 2) return;

    final lastTwo = coords.sublist(coords.length - 2);

    // Evitem duplicar processos si el segment és idèntic en el canvi de segon
    if (_lastAnimatedSegment != null &&
        _lastAnimatedSegment![0][0] == lastTwo[0][0] &&
        _lastAnimatedSegment![0][1] == lastTwo[0][1] &&
        _lastAnimatedSegment![1][0] == lastTwo[1][0] &&
        _lastAnimatedSegment![1][1] == lastTwo[1][1]) {
      return;
    }

    _lastAnimatedSegment = lastTwo;

    // ─── INTERPOLACIÓ LINEAL DEL NOU TRAM (CREIXEMENT PROGRESSIU) ───
    final startLon = lastTwo[0][0];
    final startLat = lastTwo[0][1];
    final endLon = lastTwo[1][0];
    final endLat = lastTwo[1][1];

    const steps = 20; // Passos de creixement del nou quilòmetre
    const dt = Duration(milliseconds: 25);

    for (int i = 0; i <= steps; i++) {
      Future.delayed(dt * i, () {
        final t = i / steps;

        // Calculem on es troba el tall progressiu del segment en el microsegon 't'
        final currentInterpLon = startLon + (endLon - startLon) * t;
        final currentInterpLat = startLat + (endLat - startLat) * t;

        // Reconstruïm una llista provisional de geometries que s'està estenent
        final listProvisional = [
          ...coords.sublist(0, coords.length - 1),
          [currentInterpLon, currentInterpLat],
        ];

        // Actualitzem la línia principal del mapa perquè sembli que creix metre a metre
        setTrackLineGeometry(controller, listProvisional);

        // A sobre pintem la capa de pols de color vermell elèctric intermitent
        final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
        setAnimatingSegmentGeometry(controller, [
          [startLon, startLat],
          [currentInterpLon, currentInterpLat],
        ]);

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

    // Al final del cicle, fixem la llista de referència
    _lastTrack = coords;
  }

  void _updateFullTrack(List<List<double>> coords) {
    if (_lastTrack == coords) return;
    setTrackLineGeometry(controller, coords);
    _lastTrack = coords;
  }
}
