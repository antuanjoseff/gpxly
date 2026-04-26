import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpxly/models/waypoint.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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

  // -------------------------
  // LAYER: imported_track_layer
  // -------------------------
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
  // SOURCE: track_line
  // -------------------------
  await controller.addSource(
    "track_line",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // -------------------------
  // LAYER: track_line_layer
  // -------------------------
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
  // LAYER: user_location_layer
  // -------------------------
  await controller.addLayer(
    "user_location",
    "user_location_layer",
    const SymbolLayerProperties(iconImage: "user_icon", iconSize: 1.0),
  );
}

/// Actualitza la posició del punt blau
void updateMapPosition(
  MapLibreMapController controller,
  double lat,
  double lon,
  bool userMovedMap,
  void Function(bool) onAnimate,
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
  if (!userMovedMap) {
    onAnimate(true);
    controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon))).then((
      _,
    ) {
      onAnimate(false);
    });
  }
}

void updateWaypointsOnMap(
  MapLibreMapController controller,
  List<Waypoint> waypoints,
) {
  final features = waypoints.map((wp) {
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [wp.lon, wp.lat],
      },
      "properties": {"name": wp.name},
    };
  }).toList();

  controller.setGeoJsonSource('waypoints_source', {
    "type": "FeatureCollection",
    "features": features,
  });
}

Future<void> animateWaypointAppearance(MapLibreMapController controller) async {
  const int steps = 10;
  const Duration stepDuration = Duration(milliseconds: 20);

  for (int i = 0; i <= steps; i++) {
    final double t = i / steps;

    await controller.setLayerProperties(
      'waypoints_layer',
      SymbolLayerProperties(
        iconSize: 0.05 + (0.25 * t), // 0.05 → 0.30
        iconOpacity: t,
      ),
    );

    await Future.delayed(stepDuration);
  }
}

Future<void> setupWaypointLayers(MapLibreMapController controller) async {
  final ByteData wpBytes = await rootBundle.load('assets/icon/waypoint.png');
  final Uint8List wpIcon = wpBytes.buffer.asUint8List();
  await controller.addImage('waypoint_icon', wpIcon);

  await controller.addSource(
    'waypoints_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    'waypoints_source',
    'waypoints_layer',
    const SymbolLayerProperties(
      iconImage: 'waypoint_icon',
      iconSize: 0.05,
      iconOpacity: 0.0,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      iconAnchor: "bottom",
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
