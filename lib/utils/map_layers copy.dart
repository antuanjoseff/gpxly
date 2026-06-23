import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
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

  controller.setLayerProperties(
    "waypoints_recorded_layer",
    const CircleLayerProperties(circleRadius: 8.0),
  );

  controller.setLayerProperties(
    "waypoints_imported_layer",
    const CircleLayerProperties(circleRadius: 8.0),
  );

  _pulseValue = 0.0;
  _pulseIncreasing = true;
}

void _updateWaypointPulse(MapLibreMapController controller) {
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
}

/// Configura les capes del mapa:
/// - track_line (línia vermella)
/// - user_location (punt blau)
Future<void> setupUserLocationLayer(MapLibreMapController controller) async {
  // -------------------------
  // SOURCE: imported_track
  // -------------------------
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
      lineColor: "#00A8E8", // blau clar
      lineWidth: 4.0,
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  // -------------------------
  // SOURCE: track_line (La línia "fixa" consolidada)
  // -------------------------
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

  // -------------------------
  // NUEVO - SOURCE: track_animating_segment (El tram que s'estira)
  // -------------------------
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
      lineColor: "#FF0000", // Mateix vermell
      lineWidth: 4.0,
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  // -------------------------
  // ICONA PUNT BLAU
  // -------------------------
  final Uint8List blueDot = await _createBlueDot();
  await controller.addImage("user_icon", blueDot);

  // -------------------------
  // SOURCE: user_location
  // -------------------------
  await controller.addSource(
    "user_location",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // -------------------------
  // LAYER: user_location_layer (Sempre l'última perquè quedi a dalt)
  // -------------------------
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

/// Actualitza la posició del punt blau
void updateMapPosition(
  MapLibreMapController controller,
  double lat,
  double lon,
  bool userMovedMap,
  void Function(bool) onAnimate, {
  bool centerCamera = true,
}) {
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
    controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon))).then((
      _,
    ) {
      onAnimate(false);
    });
  }
}

void updateWaypointSource(
  MapLibreMapController controller,
  String sourceId,
  List<Waypoint> waypoints,
) {
  final features = waypoints.map((wp) {
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [wp.lon, wp.lat],
      },
      "properties": {
        "name": wp.name,
        "waypoint_id": wp.id, // 👈 AQUESTA LÍNIA ÉS CRÍTICA
      },
    };
  }).toList();

  controller.setGeoJsonSource(sourceId, {
    "type": "FeatureCollection",
    "features": features,
  });
}

//  WAYPOINTS LAYERS
Future<void> animateWaypointAppearance(
  MapLibreMapController controller,
  String layerId,
) async {
  const int steps = 10;
  const Duration stepDuration = Duration(milliseconds: 20);

  for (int i = 0; i <= steps; i++) {
    final double t = i / steps;

    // 🟢 ACTUALITZAT: Apliquem l'animació sobre les opacitats del cercle vectorial natiu
    await controller.setLayerProperties(
      layerId,
      CircleLayerProperties(circleOpacity: t, circleStrokeOpacity: t),
    );

    await Future.delayed(stepDuration);
  }
}

Future<void> setupWaypointLayers(MapLibreMapController controller) async {
  // 1. SOURCE: recorded (Font de dades per a fites gravades)
  await controller.addSource(
    'waypoints_recorded_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // 2. SOURCE: imported (Font de dades per a fites importades)
  await controller.addSource(
    'waypoints_imported_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // 3. recorded (Fites gravades actives a la ruta)
  await controller.addLayer(
    'waypoints_recorded_source',
    'waypoints_recorded_layer',
    const CircleLayerProperties(
      circleRadius: 8.0, // Mida de l'esfera interior sòlida [INDEX]
      circleColor: "#4CAF50", // El teu verd corporatiu de Senda [INDEX]
      circleStrokeWidth: 2.0, // Vora exterior de contrast [INDEX]
      circleStrokeColor:
          "#FFFFFF", // Blanca pura obligatòria per a fons foscos [INDEX]
      circleOpacity:
          0.0, // Comença invisible per coordinar-se amb l'animació [INDEX]
      circleStrokeOpacity: 0.0,
    ),
  );

  // LAYER: imported (Fites importades del fitxer GPX de referència)
  await controller.addLayer(
    'waypoints_imported_source',
    'waypoints_imported_layer',
    const CircleLayerProperties(
      circleRadius: 8.0, // Mida simètrica [INDEX]
      circleColor: "#00A8E8", // Blau clàssic de guia de Senda [INDEX]
      circleStrokeWidth: 2.0, // Vora exterior de contrast [INDEX]
      circleStrokeColor: "#FFFFFF",
      circleOpacity:
          0.0, // Comença invisible per coordinar-se amb l'animació [INDEX]
      circleStrokeOpacity: 0.0,
    ),
  );
}

/// Crea un cercle blau com a icona del punt de l’usuari
Future<Uint8List> _createBlueDot() async {
  const int size = 120; // Espai suficient per l'ombra
  const double center = size / 2;

  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  // 1. L'OMBRA (Indispensable perquè el punt no es perdi en zones fosques del mapa)
  final shadowPaint = Paint()
    ..color = AppColors.dark.withAlpha(50)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawCircle(const Offset(center, center + 3), 32, shadowPaint);

  // 2. EL CERCLE DE REREFONS (Aura de precisió - Opcional)
  // És aquest cercle blau molt clar que sol envoltar el punt
  final auraPaint = Paint()..color = AppColors.skyBlue.withAlpha(40);
  canvas.drawCircle(const Offset(center, center), 55, auraPaint);

  // 3. LA VORA BLANCA (Dona molta claredat visual)
  final borderPaint = Paint()..color = Colors.white;
  canvas.drawCircle(const Offset(center, center), 34, borderPaint);

  // 4. EL PUNT PRINCIPAL (Color sòlid)
  final dotPaint = Paint()
    ..color = AppColors.skyBlue
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(center, center), 28, dotPaint);

  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// AFEGEIX A map_layers.dart

void setTrackLineGeometry(
  MapLibreMapController controller,
  List<List<double>> coordinates,
) {
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
}

void setDemBoundsGeometry(
  MapLibreMapController controller,
  List<DemBounds> cells,
) {
  final List<Map<String, dynamic>> features = [];

  for (final cell in cells) {
    features.add({
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [cell.minLon, cell.minLat], // 1. Abajo-Izquierda
            [cell.maxLon, cell.minLat], // 2. Abajo-Derecha
            [cell.maxLon, cell.maxLat], // 3. Arriba-Derecha
            [cell.minLon, cell.maxLat], // 4. Arriba-Izquierda
            [cell.minLon, cell.minLat], // 5. Cierre geométrico
          ],
        ],
      },
    });
  }

  controller.setGeoJsonSource("dem_bounds_source", {
    "type": "FeatureCollection",
    "features": features,
  });
}

void setAnimatingSegmentGeometry(
  MapLibreMapController controller,
  List<List<double>> coordinates,
) {
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
}

void setUserLocationGeometry(
  MapLibreMapController controller,
  double lat,
  double lon,
) {
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
}

/// Actualitza les fites geomètriques de la interacció del gràfic sobre el mapa
Future<void> setChartInteractionGeometry(
  MapLibreMapController controller, {
  List<double>? hoverCoords,
  List<double>? rangeStartCoords,
  List<double>? rangeEndCoords,
}) async {
  final List<Map<String, dynamic>> features = [];

  // 1. Mira de Drag Simple (Punt taronja en moviment)
  if (hoverCoords != null && hoverCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "hover"},
      "geometry": {
        "type": "Point",
        "coordinates": hoverCoords, // Llista [lon, lat] plana corregida
      },
    });
  }

  // 2. Extrem d'Inici del Tram o Punt d'Inici del Drag (Punt verd fix)
  if (rangeStartCoords != null && rangeStartCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "range_start"},
      "geometry": {
        "type": "Point",
        "coordinates": rangeStartCoords, // Llista [lon, lat] plana corregida
      },
    });
  }

  // 3. Extrem de Final del Tram (Punt vermell fix)
  if (rangeEndCoords != null && rangeEndCoords.length == 2) {
    features.add({
      "type": "Feature",
      "properties": {"type": "range_end"},
      "geometry": {
        "type": "Point",
        "coordinates": rangeEndCoords, // Llista [lon, lat] plana corregida
      },
    });
  }

  final geojson = {"type": "FeatureCollection", "features": features};

  try {
    // Intentem injectar les dades de manera normal si la font ja existeix
    await controller.setGeoJsonSource("chart_interaction_source", geojson);
  } catch (e) {
    // 🛡️ RECOVERY EN CAS QUE L'ESTIL EN MEMÒRIA S'HAGI REINICIAT O CARREGAT DE NOU
    try {
      await controller.addSource(
        "chart_interaction_source",
        GeojsonSourceProperties(data: geojson),
      );

      // A. CREEM L'INDICADOR TARONJA (Mira en moviment)
      await controller.addLayer(
        "chart_interaction_source",
        "chart_hover_layer",
        const CircleLayerProperties(
          circleRadius: 7.0,
          circleColor: "#FF9800",
          circleStrokeWidth: 2.0,
          circleStrokeColor: "#FFFFFF",
        ),
      );
      await controller.setFilter("chart_hover_layer", ["==", "type", "hover"]);

      // B. CREEM L'INDICADOR VERD (Inici del tram) -> CORREGIT: 'CircleLayerProperties'
      await controller.addLayer(
        "chart_interaction_source",
        "chart_start_layer",
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: "#4CAF50", // El color Verd de fàbrica de Senda
          circleStrokeWidth: 2.5,
          circleStrokeColor: "#FFFFFF",
        ),
      );
      await controller.setFilter("chart_start_layer", [
        "==",
        "type",
        "range_start",
      ]);

      // C. CREEM L'INDICADOR VERMELL (Final del tram) -> CORREGIT: 'CircleLayerProperties'
      await controller.addLayer(
        "chart_interaction_source",
        "chart_end_layer",
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: "#F44336", // El color Vermell de fàbrica de Senda
          circleStrokeWidth: 2.5,
          circleStrokeColor: "#FFFFFF",
        ),
      );
      await controller.setFilter("chart_end_layer", [
        "==",
        "type",
        "range_end",
      ]);
    } catch (innerError) {
      debugPrint(
        "⚠️ Errada interna en assegurar les capes de la GPU: \$innerError",
      );
    }
  }
}
