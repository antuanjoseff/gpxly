// lib/screens/main_map/utils/map_layers.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/theme/app_colors.dart';

Timer? _waypointPulseTimer;
double _pulseValue = 0.0;
bool _pulseIncreasing = true;

void startWaypointPulse(MapLibreMapController controller) {
  _waypointPulseTimer ??= Timer.periodic(
    const Duration(milliseconds: 80),
    (_) => _updateWaypointPulse(controller),
  );
}

void stopWaypointPulse(MapLibreMapController controller) {
  _waypointPulseTimer?.cancel();
  _waypointPulseTimer = null;

  try {
    controller.setLayerProperties(
      "waypoints_recorded_layer",
      CircleLayerProperties(circleRadius: 8.0),
    );

    controller.setLayerProperties(
      "waypoints_imported_layer",
      CircleLayerProperties(circleRadius: 8.0),
    );
  } catch (e) {
    debugPrint("⚠️ No s'ha pogut restaurar el radi base al aturar el pols: $e");
  }

  _pulseValue = 0.0;
  _pulseIncreasing = true;
}

void _updateWaypointPulse(MapLibreMapController controller) {
  try {
    const double baseRadius = 8.0;
    final double radius = baseRadius + _pulseValue;

    controller.setLayerProperties(
      "waypoints_recorded_layer",
      CircleLayerProperties(circleRadius: radius),
    );

    controller.setLayerProperties(
      "waypoints_imported_layer",
      CircleLayerProperties(circleRadius: radius),
    );

    if (_pulseIncreasing) {
      _pulseValue += 0.25;
      if (_pulseValue >= 2.0) _pulseIncreasing = false;
    } else {
      _pulseValue -= 0.25;
      if (_pulseValue <= 0.0) _pulseIncreasing = true;
    }
  } catch (e) {
    _waypointPulseTimer?.cancel();
    _waypointPulseTimer = null;
    debugPrint("⚠️ Temporitzador de pols cancel·lat per seguretat: $e");
  }
}

Future<void> setupUserLocationLayer(MapLibreMapController controller) async {
  await controller.addSource(
    "imported_track",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    "imported_track",
    "imported_track_layer",
    const LineLayerProperties(
      lineColor: "#00A8E8",
      lineWidth: 4.0,
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  await controller.addSource(
    "track_line",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    "track_line",
    "track_line_layer",
    const LineLayerProperties(
      lineColor: "#FF0000",
      lineWidth: 4.0,
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  await controller.addSource(
    "track_animating_segment",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    "track_animating_segment",
    "track_animating_layer",
    const LineLayerProperties(
      lineColor: "#FF0000",
      lineWidth: 4.0,
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  final Uint8List blueDot = await _createBlueDot();
  await controller.addImage("user_icon", blueDot);

  await controller.addSource(
    "user_location",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    "user_location",
    "user_location_layer",
    const SymbolLayerProperties(
      iconImage: "user_icon",
      iconSize: 1.0,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
    ),
  );
}

void updateMapPosition(
  MapLibreMapController controller,
  double lat,
  double lon,
  bool userMovedMap,
  void Function(bool) onAnimate, {
  bool centerCamera = true,
}) {
  try {
    controller.setGeoJsonSource("user_location", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lon, lat],
          },
        },
      ],
    });

    if (!userMovedMap && centerCamera) {
      onAnimate(true);
      controller
          .animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon)))
          .then((_) {
            onAnimate(false);
          })
          .catchError((e) {
            onAnimate(false);
          });
    }
  } catch (e) {
    debugPrint("⚠️ Error en actualitzar la posició del mapa: $e");
  }
}

void updateWaypointSource(
  MapLibreMapController controller,
  String sourceId,
  List<Waypoint> waypoints,
) {
  try {
    final features = waypoints.map((wp) {
      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [wp.lon, wp.lat],
        },
        "properties": {"name": wp.name, "waypoint_id": wp.id},
      };
    }).toList();

    controller.setGeoJsonSource(sourceId, {
      "type": "FeatureCollection",
      "features": features,
    });
  } catch (e) {
    debugPrint("⚠️ No s'ha pogut injectar el geojson a la font $sourceId: $e");
  }
}

Future<void> animateWaypointAppearance(
  MapLibreMapController controller,
  String layerId,
) async {
  const int steps = 10;
  const Duration stepDuration = Duration(milliseconds: 20);

  for (int i = 0; i <= steps; i++) {
    final double t = i / steps;
    try {
      await controller.setLayerProperties(
        layerId,
        CircleLayerProperties(circleOpacity: t, circleStrokeOpacity: t),
      );
    } catch (e) {
      debugPrint("⚠️ L'animació s'ha interromput: $e");
      break;
    }
    await Future.delayed(stepDuration);
  }
}

Future<void> setupWaypointLayers(MapLibreMapController controller) async {
  await controller.addSource(
    'waypoints_recorded_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addSource(
    'waypoints_imported_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // 🚀 BLINDATGE DE LA GPU DE MAPLIBRE:
  // Forcem tots els valors numèrics de gruix i opacitat a doubles estrictes
  await controller.addLayer(
    'waypoints_recorded_source',
    'waypoints_recorded_layer',
    const CircleLayerProperties(
      circleRadius: 8.0,
      circleColor: "#4CAF50",
      circleStrokeWidth: 2.0,
      circleStrokeColor: "#FFFFFF",
      circleOpacity: 0.0,
      circleStrokeOpacity: 0.0,
      circleBlur: 0.0,
    ),
  );

  await controller.addLayer(
    'waypoints_imported_source',
    'waypoints_imported_layer',
    const CircleLayerProperties(
      circleRadius: 8.0,
      circleColor: "#00A8E8",
      circleStrokeWidth: 2.0,
      circleStrokeColor: "#FFFFFF",
      circleOpacity: 0.0,
      circleStrokeOpacity: 0.0,
      circleBlur: 0.0,
    ),
  );
}

Future<Uint8List> _createBlueDot() async {
  const int size = 120;
  const double center = size / 2;

  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  final shadowPaint = Paint()
    ..color = AppColors.dark.withAlpha(50)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawCircle(const Offset(center, center + 3), 32, shadowPaint);

  final auraPaint = Paint()..color = AppColors.skyBlue.withAlpha(40);
  canvas.drawCircle(const Offset(center, center), 55, auraPaint);

  final borderPaint = Paint()..color = Colors.white;
  canvas.drawCircle(const Offset(center, center), 34, borderPaint);

  final dotPaint = Paint()
    ..color = AppColors.skyBlue
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(center, center), 28, dotPaint);

  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void setTrackLineGeometry(
  MapLibreMapController controller,
  List<List<double>> coordinates,
) {
  try {
    controller.setGeoJsonSource("track_line", {
      "type": "FeatureCollection",
      "features": coordinates.isEmpty
          ? []
          : [
              {
                "type": "Feature",
                "geometry": {"type": "LineString", "coordinates": coordinates},
              },
            ],
    });
  } catch (e) {
    debugPrint("⚠️ Error al setTrackLineGeometry: $e");
  }
}

void setDemBoundsGeometry(
  MapLibreMapController controller,
  List<DemBounds> cells,
) {
  try {
    final List<Map<String, dynamic>> features = [];

    for (final cell in cells) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [cell.minLon, cell.minLat],
              [cell.maxLon, cell.minLat],
              [cell.maxLon, cell.maxLat],
              [cell.minLon, cell.maxLat],
              [cell.minLon, cell.minLat],
            ],
          ],
        },
      });
    }

    controller.setGeoJsonSource("dem_bounds_source", {
      "type": "FeatureCollection",
      "features": features,
    });
  } catch (e) {
    debugPrint("⚠️ Error al setDemBoundsGeometry: $e");
  }
}

void setAnimatingSegmentGeometry(
  MapLibreMapController controller,
  List<List<double>> coordinates,
) {
  try {
    controller.setGeoJsonSource("track_animating_segment", {
      "type": "FeatureCollection",
      "features": coordinates.isEmpty
          ? []
          : [
              {
                "type": "Feature",
                "geometry": {"type": "LineString", "coordinates": coordinates},
              },
            ],
    });
  } catch (e) {
    debugPrint("⚠️ Error al setAnimatingSegmentGeometry: $e");
  }
}

void setUserLocationGeometry(
  MapLibreMapController controller,
  double lat,
  double lon,
) {
  try {
    controller.setGeoJsonSource("user_location", {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lon, lat],
          },
        },
      ],
    });
  } catch (e) {
    debugPrint("⚠️ Error al setUserLocationGeometry: $e");
  }
}

// lib/screens/main_map/utils/map_layers.dart (CORREGIT DEFINITIU)

Future<void> setChartInteractionGeometry(
  MapLibreMapController controller, {
  List<double>? hoverCoords,
  List<double>? rangeStartCoords,
  List<double>? rangeEndCoords,
}) async {
  final List<Map<String, dynamic>> features = [];

  if (hoverCoords != null && hoverCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "hover"},
      "geometry": {"type": "Point", "coordinates": hoverCoords},
    });
  }

  if (rangeStartCoords != null && rangeStartCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "range_start"},
      "geometry": {"type": "Point", "coordinates": rangeStartCoords},
    });
  }

  if (rangeEndCoords != null && rangeEndCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "range_end"},
      "geometry": {"type": "Point", "coordinates": rangeEndCoords},
    });
  }

  final geojson = {"type": "FeatureCollection", "features": features};

  try {
    await controller.setGeoJsonSource("chart_interaction_source", geojson);
  } catch (e) {
    try {
      await controller.addSource(
        "chart_interaction_source",
        GeojsonSourceProperties(data: geojson),
      );

      // A. CAPA TARANJA (Hover) - Blindada amb tots els tipus explícits
      await controller.addLayer(
        "chart_interaction_source",
        "chart_hover_layer",
        const CircleLayerProperties(
          circleRadius: 7.0,
          circleColor: "#FF9800",
          circleStrokeWidth: 2.0,
          circleStrokeColor: "#FFFFFF",
          circleOpacity: 1.0, // 🚀 Forcem double, mai text
          circleStrokeOpacity: 1.0, // 🚀 Forcem double, mai text
          circleBlur: 0.0,
        ),
      );
      await controller.setFilter("chart_hover_layer", [
        "==",
        ["get", "type"],
        "hover",
      ]);

      // B. CAPA VERDA (Inicio) - Blindada amb tots els tipus explícits
      await controller.addLayer(
        "chart_interaction_source",
        "chart_start_layer",
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: "#4CAF50",
          circleStrokeWidth: 2.5,
          circleStrokeColor: "#FFFFFF",
          circleOpacity: 1.0,
          circleStrokeOpacity: 1.0,
          circleBlur: 0.0,
        ),
      );
      await controller.setFilter("chart_start_layer", [
        "==",
        ["get", "type"],
        "range_start",
      ]);

      // C. CAPA ROJA (Fin) - Blindada amb tots els tipus explícits
      await controller.addLayer(
        "chart_interaction_source",
        "chart_end_layer",
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: "#F44336",
          circleStrokeWidth: 2.5,
          circleStrokeColor: "#FFFFFF",
          circleOpacity: 1.0,
          circleStrokeOpacity: 1.0,
          circleBlur: 0.0,
        ),
      );
      await controller.setFilter("chart_end_layer", [
        "==",
        ["get", "type"],
        "range_end",
      ]);
    } catch (innerError) {
      debugPrint(
        "⚠️ Errada interna en assegurar les capes de la GPU: $innerError",
      );
    }
  }
}

// 🎯 MOVEM LA FUNCIÓ FORA (Estava niada de forma incorrecta dins de l'altre Future!)
Future<void> updateSelectionCircles(
  MapLibreMapController controller,
  ElevationSelectionState sel,
  List<List<double>> trackCoords,
) async {
  if (trackCoords.isEmpty) return;

  if (sel.startTrackIndex == null && sel.endTrackIndex == null) {
    await controller.setGeoJsonSource("chart_interaction_source", {
      "type": "FeatureCollection",
      "features": [],
    });
    return; // 🎯 Tallem l'execució aquí
  }

  List<double>? startCoords;
  List<double>? endCoords;

  // Validem que els indexs de Riverpod no estiguin fora dels límits de la llista real del mapa
  if (sel.startTrackIndex != null &&
      sel.startTrackIndex! < trackCoords.length) {
    startCoords = trackCoords[sel.startTrackIndex!];
  }

  if (sel.endTrackIndex != null && sel.endTrackIndex! < trackCoords.length) {
    endCoords = trackCoords[sel.endTrackIndex!];
  }

  await setChartInteractionGeometry(
    controller,
    rangeStartCoords: startCoords,
    rangeEndCoords: endCoords,
  );
}
