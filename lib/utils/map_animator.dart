// lib/utils/map_animator.dart
import 'dart:async';
import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/utils/map_layers.dart';

class MapAnimator {
  final MapLibreMapController controller;

  LatLng? _lastUserPos;
  List<List<double>>? _lastTrack;
  List<List<double>>? _lastAnimatedSegment;

  // ─── CONTROL DEL SEMÁFORO DE ANIMACIÓN CRÍTICO ───
  Timer? _activeTimer;
  bool isAnimating = false;

  MapAnimator(this.controller);

  // ─────────────────────────────────────────────────────────────
  // 🛰️ 0. NOU CENTRE DE MAPA SEGONS PADDING INFERIOR
  // ─────────────────────────────────────────────────────────────
  LatLng _calculateOffsetTarget(LatLng position, double padding) {
    // 1. Obtenim el zoom real actual de la càmera
    final double currentZoom = controller.cameraPosition?.zoom ?? 14.0;

    // 2. Calculem els píxels que volem desplaçar cap avall (la meitat de l'espai visible ocupat)
    final double pixelsToMove = padding / 2;

    // 3. Convertim la latitud de l'usuari a radiants per calcular el cosinus (escala Mercator)
    final double latRadians = position.latitude * (pi / 180.0);

    // 4. Mida geomètrica exacta: 1.40625 graus multiplicat per la deformació de la pantalla
    final double degreesPerPixel =
        (1.40625 * cos(latRadians)) / (1 << currentZoom.toInt());

    // 5. Multipliquem els píxels de marge per l'escala final de graus
    final double latOffset = pixelsToMove * degreesPerPixel;

    // 6. Restem els graus exactes a la latitud per moure la càmera al sud
    return LatLng(position.latitude - latOffset, position.longitude);
  }

  // ─────────────────────────────────────────────────────────────
  // 🛰️ 1. LLISCAMENT DEL CERCLE BLAU (Mantenim l'oient A del GPS)
  // ─────────────────────────────────────────────────────────────
  void animateUserPosition(LatLng? newPos, {double bottomPadding = 0.0}) {
    if (newPos == null || isAnimating)
      return; // Si està corrent la gravació, el bucle unificat ja ho mourà

    // newPos = _calculateOffsetTarget(newPos, bottomPadding);
    if (_lastUserPos == null) {
      setUserLocationGeometry(controller, newPos.latitude, newPos.longitude);
      _lastUserPos = newPos;
      return;
    }

    _lastUserPos = newPos;
    final from = _lastUserPos!;
    final to = newPos;

    const steps = 15;
    const dt = Duration(milliseconds: 16);

    for (int i = 0; i <= steps; i++) {
      Future.delayed(dt * i, () {
        if (isAnimating) return; // Salvaguarda si arrenca una passa de track
        final t = i / steps;
        final lat = from.latitude + (to.latitude - from.latitude) * t;
        final lon = from.longitude + (to.longitude - from.longitude) * t;
        setUserLocationGeometry(controller, lat, lon);
      });
    }

    _lastUserPos = newPos;
  }

  // ─────────────────────────────────────────────────────────────
  // 📊 2. MOTOR UNIFICAT FLUID DE CREIXEMENT DE LA RUTA (Batec Track)
  // ─────────────────────────────────────────────────────────────
  void updateFromTrack(Track track, bool userMovedMap) {
    _animateTrackProgress(
      track.coordinates,
      track.recordingState,
      userMovedMap,
    );
  }

  void _animateTrackProgress(
    List<List<double>> coords,
    RecordingState state,
    bool userMovedMap,
  ) {
    if (state != RecordingState.recording) {
      _updateFullTrack(coords);
      if (coords.isNotEmpty) {
        _lastUserPos = LatLng(coords.last[1], coords.last[0]);
        setUserLocationGeometry(
          controller,
          _lastUserPos!.latitude,
          _lastUserPos!.longitude,
        );
      }
      return;
    }
    if (coords.length < 2) return;

    final lastTwo = coords.sublist(coords.length - 2);

    // Evitem re-animar si el fragment del segon és exactament el mateix
    if (_lastAnimatedSegment != null &&
        _lastAnimatedSegment![0][0] == lastTwo[0][0] &&
        _lastAnimatedSegment![0][1] == lastTwo[0][1] &&
        _lastAnimatedSegment![1][0] == lastTwo[1][0] &&
        _lastAnimatedSegment![1][1] == lastTwo[1][1]) {
      return;
    }

    _lastAnimatedSegment = lastTwo;

    // Si hi ha un temporitzador vell corrent en segon pla, el matem del tot abans de trepitjar
    _activeTimer?.cancel();

    final double startLon = lastTwo[0][0];
    final double startLat = lastTwo[0][1];
    final double endLon = lastTwo[1][0];
    final double latFinalDesti = lastTwo[1][1];

    int currentStep = 0;
    const int totalSteps = 15; // Passos de la interpolació cinemàtica

    isAnimating = true;

    // Arrenquem un ÚNIC rellotge controlat per a coordinar totes les geometries
    _activeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      currentStep++;
      final double t = currentStep / totalSteps;

      // Calculem la posició interpolada exacta del microsegon actual 't'
      final double animatedLat = startLat + (latFinalDesti - startLat) * t;
      final double animatedLon = startLon + (endLon - startLon) * t;

      // A) LLISCAMENT SÍNCRON DEL PUNT BLAU (Es mou al mateix mil·límetre que el traç)
      setUserLocationGeometry(controller, animatedLat, animatedLon);
      _lastUserPos = LatLng(animatedLat, animatedLon);

      // B) CREIXEMENT PROGRESSIU DE LA LÍNIA PRINCIPAL NEGRA/VERMELLA
      final animatedCoordinates = [
        ...coords.sublist(0, coords.length - 1),
        [animatedLon, animatedLat],
      ];
      setTrackLineGeometry(controller, animatedCoordinates);

      // C) CAPA SUPERIOR DE POLS VERMELL ELÈCTRIC INTERMITENT (Efecte pols de radar)
      final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
      setAnimatingSegmentGeometry(controller, [
        [startLon, startLat],
        [animatedLon, animatedLat],
      ]);

      controller.setLayerProperties(
        "track_animating_layer",
        LineLayerProperties(
          lineOpacity: opacity,
          lineColor: "#FF0000",
          lineWidth: 4.0,
        ),
      );

      // 🏁 FINAL DE LA TRANSICIÓ D'AQUEST SEGMENT
      if (currentStep >= totalSteps) {
        timer.cancel();
        _activeTimer = null;

        // Fixem la línia real geomètrica final sense retalls provisoris
        setTrackLineGeometry(controller, coords);
        _lastTrack = coords;

        // 🎥 GESTIÓ SMART CENTER: Si l'usuari no ha mogut el mapa, acompanyem el desplaçament
        if (!userMovedMap) {
          controller.animateCamera(CameraUpdate.newLatLng(_lastUserPos!)).then((
            _,
          ) {
            Future.delayed(const Duration(milliseconds: 100), () {
              isAnimating = false; // Alliberem el semàfor de control
            });
          });
        } else {
          isAnimating = false;
        }
      }
    });
  }

  void _updateFullTrack(List<List<double>> coords) {
    if (_lastTrack == coords) return;
    setTrackLineGeometry(controller, coords);
    _lastTrack = coords;
  }
}
