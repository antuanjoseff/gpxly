// lib/utils/waypoint_annotations.dart
//
// Gestor d'anotacions (Circle + Symbol) per als waypoints.
// Aquesta aproximació substitueix les capes GeoJSON per objectes Dart,
// eliminant els problemes de setLayerProperties amb skipNulls:false.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/waypoint.dart';

/// Classe que encapsula les anotacions d'un waypoint: cercle + nom
class WaypointAnnotation {
  final Circle circle;
  final Symbol symbol;
  final Waypoint waypoint;

  const WaypointAnnotation({
    required this.circle,
    required this.symbol,
    required this.waypoint,
  });
}

/// Gestor de les anotacions de waypoints
class WaypointAnnotationsManager {
  final MapLibreMapController controller;

  /// Mapa d'anotacions per ID de waypoint
  final Map<String, WaypointAnnotation> _annotations = {};

  /// Timer per al pols dels cercles
  Timer? _pulseTimer;
  double _pulseValue = 0.0;
  bool _pulseIncreasing = true;

  WaypointAnnotationsManager(this.controller);

  /// Afegeix un waypoint al mapa (cercle + nom)
  Future<void> addWaypoint(Waypoint wp) async {
    if (_annotations.containsKey(wp.id)) return;

    try {
      // 1. Dibuixem el cercle
      final circle = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(wp.lat, wp.lon),
          circleRadius: 11.0,
          circleColor: "#4CAF50",
          circleStrokeWidth: 2.0,
          circleStrokeColor: "#FFFFFF",
          circleOpacity: 1.0,
          circleStrokeOpacity: 1.0,
        ),
      );

      // 2. Dibuixem el nom just a sota
      final symbol = await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(wp.lat, wp.lon),
          textField: wp.name,
          textSize: 12.0,
          textColor: "#2E7D32",
          textHaloColor: "#FFFFFF",
          textHaloWidth: 1.5,
          // 📍 El nom penja per sota del cercle
          textAnchor: "top",
          textOffset: const Offset(0, 1.1),
        ),
      );

      _annotations[wp.id] = WaypointAnnotation(
        circle: circle,
        symbol: symbol,
        waypoint: wp,
      );

      debugPrint("✅ Waypoint ${wp.name} afegit (${wp.id})");
    } catch (e) {
      debugPrint("⚠️ Error afegint waypoint ${wp.name}: $e");
    }
  }

  /// Elimina un waypoint del mapa
  Future<void> removeWaypoint(String waypointId) async {
    final annotation = _annotations.remove(waypointId);
    if (annotation == null) return;

    try {
      await controller.removeCircle(annotation.circle);
      await controller.removeSymbol(annotation.symbol);
      debugPrint("🗑️ Waypoint eliminat ($waypointId)");
    } catch (e) {
      debugPrint("⚠️ Error eliminant waypoint $waypointId: $e");
    }
  }

  /// Actualitza el nom d'un waypoint
  Future<void> renameWaypoint(String waypointId, String newName) async {
    final annotation = _annotations[waypointId];
    if (annotation == null) return;

    try {
      // Actualitzem el text del símbol
      await controller.updateSymbol(
        annotation.symbol,
        SymbolOptions(textField: newName),
      );
      debugPrint("✏️ Waypoint reanomenat a $newName ($waypointId)");
    } catch (e) {
      debugPrint("⚠️ Error reanomenant waypoint $waypointId: $e");
    }
  }

  /// Sincronitza les anotacions amb una llista de waypoints
  /// (afegeix els nous, elimina els que ja no hi són, actualitza els canviats)
  Future<void> syncWaypoints(List<Waypoint> waypoints) async {
    final currentIds = _annotations.keys.toSet();
    final newIds = waypoints.map((w) => w.id).toSet();

    // Eliminar waypoints que ja no existeixen
    for (final id in currentIds.difference(newIds)) {
      await removeWaypoint(id);
    }

    // Afegir o actualitzar waypoints
    for (final wp in waypoints) {
      if (!currentIds.contains(wp.id)) {
        await addWaypoint(wp);
      } else {
        // Comprovar si el nom ha canviat
        final existing = _annotations[wp.id]!;
        if (existing.waypoint.name != wp.name) {
          await renameWaypoint(wp.id, wp.name);
        }
      }
    }
  }

  /// Inicia el pols dels cercles
  void startPulse() {
    _pulseTimer ??= Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _updatePulse(),
    );
  }

  /// Atura el pols i restaura el radi base
  Future<void> stopPulse() async {
    _pulseTimer?.cancel();
    _pulseTimer = null;

    // Restaurem tots els cercles al radi base
    for (final annotation in _annotations.values) {
      try {
        await controller.updateCircle(
          annotation.circle,
          CircleOptions(
            circleRadius: 11.0,
            circleOpacity: 1.0,
            circleStrokeOpacity: 1.0,
          ),
        );
      } catch (e) {
        debugPrint("⚠️ Error restaurant cercle: $e");
      }
    }

    _pulseValue = 0.0;
    _pulseIncreasing = true;
  }

  /// Actualitza el pols dels cercles
  Future<void> _updatePulse() async {
    try {
      const double baseRadius = 11.0;
      final double radius = baseRadius + _pulseValue;

      // Opacitat dinàmica inversament proporcional al radi
      final double opacity = 1.0 - (_pulseValue / 6.5);
      final double finalOpacity = opacity.clamp(0.2, 1.0);

      // Actualitzem tots els cercles
      for (final annotation in _annotations.values) {
        await controller.updateCircle(
          annotation.circle,
          CircleOptions(
            circleRadius: radius,
            circleOpacity: finalOpacity,
            circleStrokeOpacity: finalOpacity,
          ),
        );
      }

      // Increment/decrement del pols
      if (_pulseIncreasing) {
        _pulseValue += 0.5;
        if (_pulseValue >= 6.0) _pulseIncreasing = false;
      } else {
        _pulseValue -= 0.5;
        if (_pulseValue <= 0.0) _pulseIncreasing = true;
      }
    } catch (e) {
      _pulseTimer?.cancel();
      _pulseTimer = null;
      debugPrint("⚠️ Temporitzador de pols cancel·lat: $e");
    }
  }

  /// Neteja totes les anotacions
  Future<void> clear() async {
    for (final id in _annotations.keys.toList()) {
      await removeWaypoint(id);
    }
  }

  /// Dispose del gestor
  void dispose() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    _annotations.clear();
  }
}
