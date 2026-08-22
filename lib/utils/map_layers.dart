// lib/screens/main_map/utils/map_layers.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/notifiers/dem_bounds_notifier.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/theme/app_colors.dart';

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
    // 🟢 RESTAURACIÓ BLINDADA: Retornem el radi (8.0) i l'opacitat completa (1.0) natius
    controller.setLayerProperties(
      "waypoints_recorded_layer",
      const CircleLayerProperties(circleRadius: 11.0, circleOpacity: 1.0),
    );
    controller.setLayerProperties(
      "waypoints_imported_layer",
      const CircleLayerProperties(circleRadius: 11.0, circleOpacity: 1.0),
    );
  } catch (e) {
    debugPrint("⚠️ No s'ha pogut restaurar el radi base al aturar el pols: $e");
  }

  _pulseValue = 0.0;
  _pulseIncreasing = true;
}

void _updateWaypointPulse(MapLibreMapController controller) {
  try {
    const double baseRadius = 11.0;

    // 🚀 MILLORA 1: Augmentem l'amplitud del pols (abans arribava a 10.0, ara creixerà fins a 14.0)
    final double radius = baseRadius + _pulseValue;

    // 🚀 MILLORA 2: Calculem una opacitat dinàmica inversament proporcional al radi (Fade-out progressiu)
    // Quan el cercle es fa gran, es va tornant translúcid de forma molt orgànica.
    final double opacity = 1.0 - (_pulseValue / 6.5);
    final double finalOpacity = opacity.clamp(
      0.2,
      1.0,
    ); // Evitem que desaparegui del tot

    controller.setLayerProperties(
      "waypoints_recorded_layer",
      CircleLayerProperties(circleRadius: radius, circleOpacity: finalOpacity),
    );
    controller.setLayerProperties(
      "waypoints_imported_layer",
      CircleLayerProperties(circleRadius: radius, circleOpacity: finalOpacity),
    );

    // 🚀 MILLORA 3: Increments lleugerament més alts per donar un batec més viu i dinàmic
    if (_pulseIncreasing) {
      _pulseValue += 0.5; // Abans era 0.25
      if (_pulseValue >= 6.0)
        _pulseIncreasing = false; // Pic de radi màxim a 14.0
    } else {
      _pulseValue -= 0.5;
      if (_pulseValue <= 0.0) _pulseIncreasing = true;
    }
  } catch (e) {
    _waypointPulseTimer?.cancel();
    _waypointPulseTimer = null;
    debugPrint("⚠️ Temporitzador de pols cancel·lat per seguretat: $e");
  }
}

Future<void> setupUserLocationLayer(MapLibreMapController controller) async {
  // imported_track
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

  // track_line
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

  // selected_segment_source
  await controller.addSource(
    "selected_segment_source",
    const GeojsonSourceProperties(
      data: {"type": "FeatureCollection", "features": []},
    ),
  );

  await controller.addLayer(
    "selected_segment_source",
    "selected_segment_casing_layer",
    const LineLayerProperties(
      lineColor: "#FFFFFF", // ⚪ Blanco puro de fondo
      lineWidth:
          9.0, // 🎯 Gruesa para que sobresalga por los bordes de la naranja
      lineJoin: "round",
      lineCap: "round",
    ),
  );

  await controller.addLayer(
    "selected_segment_source",
    "selected_segment_layer",
    const LineLayerProperties(
      lineColor: "#FF9800", // 🍊 Color naranja STrack Rec
      lineWidth: 5.0, // 🎯 Más fina para centrarse sobre el fondo blanco
      lineJoin: "round",
      lineCap: "round",
      // 💡 PATRÓN DISCONTINUO: [longitud del guion, espacio en blanco] en múltiplos de grosor
      lineDasharray: [2.0, 2.0],
    ),
  );

  // track_animating_segment
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

  // user_location
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
      // 🟢 SOLUCIÓN DE COMPILACIÓN: Volvemos a la clase requerida por MapLibre,
      // pero asignando el double estricto 't' únicamente a los campos de opacidad.
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

  // 🚀 BLINDADO CONTRA EL LOG 'circle-blur Expected number but found string instead':
  // Inyectamos la configuración nativa de la GPU mediante mapas planos directos al inicializar la capa.
  try {
    await controller.addLayer(
      'waypoints_recorded_source',
      'waypoints_recorded_layer',
      const CircleLayerProperties(
        circleRadius: 11.0,
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
        circleRadius: 11.0,
        circleColor: "#00A8E8",
        circleStrokeWidth: 2.0,
        circleStrokeColor: "#FFFFFF",
        circleOpacity: 0.0,
        circleStrokeOpacity: 0.0,
        circleBlur: 0.0,
      ),
    );
  } catch (e) {
    debugPrint("⚠️ Error al dar de alta las capas de waypoints en la GPU: $e");
  }
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

bool _isChartGeometryProcessing = false;

Future<void> setChartInteractionGeometry(
  MapLibreMapController controller, {
  List<double>? hoverCoords,
  List<double>? rangeStartCoords,
  List<double>? rangeEndCoords,
}) async {
  if (_isChartGeometryProcessing) return;
  _isChartGeometryProcessing = true;

  try {
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
      // ⚡ ESTRATEGIA ULTRA RÁPIDA (Para cuando mueves el mapa):
      // Intentamos solo actualizar los datos. Al no destruir la fuente, el círculo NO parpadea.
      await controller.setGeoJsonSource("chart_interaction_source", geojson);
    } catch (e) {
      // 💥 PLAN DE CONTINGENCIA (Solo se ejecuta al "Cargar track" si la fuente no existía o fallaba):
      // Si falla la actualización simple, significa que hay que recrear el entorno de la GPU de forma segura.
      try {
        await controller.removeLayer("chart_hover_layer");
      } catch (_) {}
      try {
        await controller.removeLayer("chart_start_layer");
      } catch (_) {}
      try {
        await controller.removeLayer("chart_end_layer");
      } catch (_) {}
      try {
        await controller.removeSource("chart_interaction_source");
      } catch (_) {}

      // Creamos la fuente limpia
      await controller.addSource(
        "chart_interaction_source",
        GeojsonSourceProperties(data: geojson),
      );

      // Capa Hover (Naranja)
      await controller.addLayer(
        "chart_interaction_source",
        "chart_hover_layer",
        const CircleLayerProperties(
          circleRadius: 7.0,
          circleColor: "#FF9800",
          circleStrokeWidth: 2.0,
          circleStrokeColor: "#FFFFFF",
          circleOpacity: 1.0,
          circleStrokeOpacity: 1.0,
        ),
      );
      await controller.setFilter("chart_hover_layer", [
        "==",
        ["get", "type"],
        "hover",
      ]);

      // Capa Inicio (Verde)
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
        ),
      );
      await controller.setFilter("chart_start_layer", [
        "==",
        ["get", "type"],
        "range_start",
      ]);

      // Capa Fin (Roja)
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
        ),
      );
      await controller.setFilter("chart_end_layer", [
        "==",
        ["get", "type"],
        "range_end",
      ]);
    }
  } catch (globalError) {
    debugPrint(
      "⚠️ Errada crítica en assegurar les capes de la GPU: $globalError",
    );
  } finally {
    _isChartGeometryProcessing = false;
  }
}

// 🎯 MOVEM LA FUNCIÓ FORA (Estava niada de forma incorrecta dins de l'altre Future!)
Future<void> updateSelectionCircles(
  MapLibreMapController controller,
  ElevationSelectionState sel,
  List<List<double>> trackCoords,
) async {
  if (trackCoords.isEmpty) return;

  // Cas 1: No hi ha cap punt seleccionat (neteja de la gràfica)
  if (sel.startTrackIndex == null && sel.endTrackIndex == null) {
    // 🚀 NOVETAT: En estat 'selected' NO netegem els cercles
    if (sel.mapToolState == MapSelectionToolState.selected) {
      return;
    }

    if (sel.mode == SelectionMode.none) {
      return;
    }

    try {
      await controller.setGeoJsonSource("chart_interaction_source", {
        "type": "FeatureCollection",
        "features": [],
      });
    } on PlatformException catch (_) {}

    return;
  }

  // Cas 2: Hi ha punts seleccionats, calculem coordenades
  List<double>? startCoords;
  List<double>? endCoords;

  // Validem que els índexs de Riverpod no estiguin fora dels límits de la llista real del mapa
  if (sel.startTrackIndex != null &&
      sel.startTrackIndex! < trackCoords.length) {
    startCoords = trackCoords[sel.startTrackIndex!];
  }

  if (sel.endTrackIndex != null && sel.endTrackIndex! < trackCoords.length) {
    endCoords = trackCoords[sel.endTrackIndex!];
  }

  // Enviem les coordenades calculades a la geometria del mapa
  try {
    await setChartInteractionGeometry(
      controller,
      rangeStartCoords: startCoords,
      rangeEndCoords: endCoords,
    );
  } on PlatformException catch (e) {
    // 🛡️ Evitem el crash també aquí si la font falla durant l'actualització de coordenades
    print(
      "MapLibre: Error en establir la geometria d'interacció: ${e.message}",
    );
  }
}

/// Dibuja la línea naranja del tramo (sea definitivo o elástico/provisional)
/// Dibuja la línea del tramo seleccionado de forma unificada:
/// Sempre es mostrarà amb un fons blanc gruixut i una línia taronja discontínua a sobre,
/// tant per a tracks gravats com per a importats.
Future<void> updateSelectedSegmentGeometry(
  MapLibreMapController controller,
  ElevationSelectionState sel,
  List<List<double>> trackCoords,
) async {
  try {
    // 1. Preparar les coordenades del segment de forma segura (Definitiu o elàstic)
    List<List<double>> segmentCoords = [];

    if (trackCoords.isNotEmpty && sel.startTrackIndex != null) {
      final int inicio = sel.startTrackIndex!;
      final int? fin = sel.mapToolState == MapSelectionToolState.selected
          ? sel.endTrackIndex
          : (sel.endTrackIndex ?? sel.provisionalEndIndex);

      if (fin != null &&
          inicio < trackCoords.length &&
          fin < trackCoords.length) {
        final int menor = inicio < fin ? inicio : fin;
        final int major = inicio > fin ? inicio : fin;
        segmentCoords = trackCoords.sublist(menor, major + 1);
      }
    }

    // 2. Construir el GeoJSON corresponent
    final geojson = {
      "type": "FeatureCollection",
      "features": segmentCoords.isEmpty
          ? []
          : [
              {
                "type": "Feature",
                "geometry": {
                  "type": "LineString",
                  "coordinates": segmentCoords,
                },
              },
            ],
    };

    // 3. Comprovar l'existència real de la font a la GPU nativa
    final List<String> existingSources = await controller.getSourceIds();
    final bool sourceExists = existingSources.contains(
      "selected_segment_source",
    );

    if (sourceExists) {
      // 🚀 Si ja existeix (cas habitual), actualitzem les dades de manera ultra veloç
      await controller.setGeoJsonSource("selected_segment_source", geojson);
    } else {
      // 🚀 Si NO existeix (contingència), la creem de zero amb les seves dues capes unificades
      await controller.addSource(
        "selected_segment_source",
        GeojsonSourceProperties(data: geojson),
      );
    }

    // 4. 🎯 ASSEGURAR LES DUES CAPES PER A L'EFECTE UNIFICAT (FONTS + GUIONS)
    final List<String> existingLayers = (await controller.getLayerIds())
        .cast<String>();

    // Capa Inferior: El fons blanc gruixut (Contorn/Casing)
    if (!existingLayers.contains("selected_segment_casing_layer")) {
      await controller.addLayer(
        "selected_segment_source",
        "selected_segment_casing_layer",
        const LineLayerProperties(
          lineColor: "#FFFFFF", // ⚪ Blanco puro de fondo
          lineWidth: 9.0, // 🎯 Gruesa para que sobresalga
          lineJoin: "round",
          lineCap: "round",
        ),
      );
    }

    // Capa Superior: La línia taronja discontínua a sobre
    if (!existingLayers.contains("selected_segment_layer")) {
      await controller.addLayer(
        "selected_segment_source",
        "selected_segment_layer",
        const LineLayerProperties(
          lineColor: "#FF9800", // 🍊 Color naranja STrack Rec
          lineWidth: 5.0, // 🎯 Más fina para centrarse sobre el fondo blanco
          lineJoin: "round",
          lineCap: "round",
          lineDasharray: [2.0, 2.0], // 💡 PATRÓN DISCONTINUO UNIFICAT
        ),
      );
    }

    // 5. Control de visibilitat segons si hi ha dades o està buit
    if (segmentCoords.isEmpty) {
      await controller.setLayerProperties(
        "selected_segment_casing_layer",
        const LineLayerProperties(visibility: "none"),
      );
      await controller.setLayerProperties(
        "selected_segment_layer",
        const LineLayerProperties(visibility: "none"),
      );
    } else {
      await controller.setLayerProperties(
        "selected_segment_casing_layer",
        const LineLayerProperties(visibility: "visible"),
      );
      await controller.setLayerProperties(
        "selected_segment_layer",
        const LineLayerProperties(visibility: "visible"),
      );
    }
  } catch (e) {
    debugPrint("⚠️ Error crítico en updateSelectedSegmentGeometry: $e");
  }
}
