// lib/services/gpx_import_flow.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/gpx_import_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Flux complet d'importació GPX + zoom al mapa.
/// Aquesta funció és cridada tant des de la bottom bar com des de l'AppBar.
Future<void> pickGpxAndImport({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
}) async {
  // 1) Obrir selector de fitxers
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['gpx'],
  );

  if (result == null) return;

  final path = result.files.single.path;
  if (path == null) return;

  // 2) Llegir el fitxer
  final xml = await File(path).readAsString();

  // 3) Importar GPX (servei existent)
  await GpxImportService.importGpx(ref, xml);

  // 4) Centrar el mapa al track importat
  final track = ref.read(trackProvider);
  if (track.coordinates.isEmpty || mapController == null) return;

  final lats = track.coordinates.map((c) => c[1]);
  final lons = track.coordinates.map((c) => c[0]);

  final bounds = LatLngBounds(
    southwest: LatLng(
      lats.reduce((a, b) => a < b ? a : b),
      lons.reduce((a, b) => a < b ? a : b),
    ),
    northeast: LatLng(
      lats.reduce((a, b) => a > b ? a : b),
      lons.reduce((a, b) => a > b ? a : b),
    ),
  );

  await mapController.animateCamera(
    CameraUpdate.newLatLngBounds(
      bounds,
      left: 40,
      right: 40,
      top: 40,
      bottom: 40,
    ),
  );
}
