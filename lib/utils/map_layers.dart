import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Configura les capes del mapa:
/// - track_line (línia vermella)
/// - user_location (punt blau)
Future<void> setupUserLocationLayer(MapLibreMapController controller) async {
  // -------------------------
  // SOURCE: track_line
  // -------------------------
  await controller.addSource(
    "track_line",
    GeojsonSourceProperties(
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
    GeojsonSourceProperties(
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

/// Crea un cercle blau com a icona del punt de l’usuari
Future<Uint8List> _createBlueDot() async {
  const int size = 64;
  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint()..color = Colors.blue;

  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
