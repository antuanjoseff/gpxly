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
  final recorded = waypoints.where((wp) => wp.trackIndex >= 0).toList();
  final imported = waypoints.where((wp) => wp.trackIndex < 0).toList();

  final recordedFeatures = recorded.map((wp) {
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [wp.lon, wp.lat],
      },
      "properties": {"name": wp.name},
    };
  }).toList();

  final importedFeatures = imported.map((wp) {
    return {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [wp.lon, wp.lat],
      },
      "properties": {"name": wp.name},
    };
  }).toList();

  controller.setGeoJsonSource('waypoints_recorded_source', {
    "type": "FeatureCollection",
    "features": recordedFeatures,
  });

  controller.setGeoJsonSource('waypoints_imported_source', {
    "type": "FeatureCollection",
    "features": importedFeatures,
  });
}

Future<void> animateWaypointAppearance(
  MapLibreMapController controller,
  String layerId,
) async {
  const int steps = 10;
  const Duration stepDuration = Duration(milliseconds: 20);

  for (int i = 0; i <= steps; i++) {
    final double t = i / steps;

    await controller.setLayerProperties(
      layerId,
      SymbolLayerProperties(iconSize: 0.05 + (0.25 * t), iconOpacity: t),
    );

    await Future.delayed(stepDuration);
  }
}

Future<void> setupWaypointLayers(MapLibreMapController controller) async {
  // ICONA WAYPOINT GRAVAT
  final ByteData wpRecordedBytes = await rootBundle.load(
    'assets/icon/waypoint.png',
  );
  final Uint8List wpRecordedIcon = wpRecordedBytes.buffer.asUint8List();
  await controller.addImage('waypoint_recorded_icon', wpRecordedIcon);

  // ICONA WAYPOINT IMPORTAT
  final ByteData wpImportedBytes = await rootBundle.load(
    'assets/icon/waypoint_imported.png',
  );
  final Uint8List wpImportedIcon = wpImportedBytes.buffer.asUint8List();
  await controller.addImage('waypoint_imported_icon', wpImportedIcon);

  // SOURCE: recorded
  await controller.addSource(
    'waypoints_recorded_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // SOURCE: imported
  await controller.addSource(
    'waypoints_imported_source',
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  // LAYER: recorded
  await controller.addLayer(
    'waypoints_recorded_source',
    'waypoints_recorded_layer',
    const SymbolLayerProperties(
      iconImage: 'waypoint_recorded_icon',
      iconSize: 0.05,
      iconOpacity: 0.0,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      iconAnchor: "bottom",
    ),
  );

  // LAYER: imported
  await controller.addLayer(
    'waypoints_imported_source',
    'waypoints_imported_layer',
    const SymbolLayerProperties(
      iconImage: 'waypoint_imported_icon',
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
