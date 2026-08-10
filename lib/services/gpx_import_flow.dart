// lib/services/gpx_import_flow.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
// ✅ ADAPTAT: Importem el proveïdor de la ruta importada de la branca
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/services/gpx_import_service.dart';

const MethodChannel _gpxUriReaderChannel = MethodChannel(
  'strack_rec/gpx_uri_reader',
);

/// Flux complet d'importació GPX + zoom al mapa.
/// Aquesta funció és cridada tant des de la bottom bar com des de l'AppBar.
Future<void> pickGpxAndImport({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['gpx'],
  );

  if (result == null) return;

  final path = result.files.single.path;
  if (path == null) return;

  await importGpxFromPath(
    context: context,
    ref: ref,
    mapController: mapController,
    path: path,
  );
}

Future<bool> importGpxFromPath({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
  required String path,
}) async {
  final uri = Uri.file(path);
  return importGpxFromUri(
    context: context,
    ref: ref,
    mapController: mapController,
    uri: uri,
  );
}

Future<bool> importGpxFromUri({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
  required Uri uri,
}) async {
  final t = AppLocalizations.of(context)!;
  final raw = uri.toString().toLowerCase();
  final isContentUri = uri.scheme == 'content';
  final hasGpxExtension =
      uri.path.toLowerCase().endsWith('.gpx') || raw.contains('.gpx');

  // 1) Validar extensió només per fitxers.
  // Amb content:// molts proveïdors no exposen l'extensió al path,
  // així que validarem pel contingut XML i etiqueta <gpx>.
  if (!isContentUri && !hasGpxExtension) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorInvalidExtension)));
    return false;
  }

  // 2) Llegir contingut
  String xml;
  try {
    xml = await _readGpxXmlFromUri(uri);
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorRead)));
    return false;
  }

  // 3) Validar XML
  if (!xml.trim().startsWith("<")) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorInvalidXml)));
    return false;
  }

  // 4) Validar etiqueta GPX
  if (!xml.contains("<gpx")) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorNoGpxTag)));
    return false;
  }

  // Importar el contingut del GPX al magatzem de dades
  await GpxImportService.importGpx(ref, xml);

  // ─── CENTRAR MAPA EN EL RECUADRE DE LA RUTA IMPORTADA ───
  // ✅ OPTIMITZAT: Llegim les coordenades i els valors del Bounding Box
  // que el model unificat ja ens dona precalculats, estalviant els bucles 'reduce'.
  final importedTrack = ref.read(importedTrackProvider);
  if (importedTrack == null ||
      importedTrack.points.isEmpty ||
      mapController == null) {
    return true;
  }

  final stats = importedTrack.stats;
  if (stats.minLat == null ||
      stats.maxLat == null ||
      stats.minLon == null ||
      stats.maxLon == null) {
    return true;
  }

  // Reconstruïm els límits de MapLibre usant els valors que el servei ja ha processat
  final bounds = LatLngBounds(
    southwest: LatLng(stats.minLat!, stats.minLon!),
    northeast: LatLng(stats.maxLat!, stats.maxLon!),
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

  return true;
}

Future<String> _readGpxXmlFromUri(Uri uri) async {
  if (uri.scheme == 'file' || uri.scheme.isEmpty) {
    final filePath = uri.scheme == 'file' ? uri.toFilePath() : uri.path;
    return File(filePath).readAsString();
  }

  if (uri.scheme == 'content') {
    final xml = await _gpxUriReaderChannel.invokeMethod<String>(
      'readTextFromUri',
      {'uri': uri.toString()},
    );

    if (xml == null || xml.isEmpty) {
      throw Exception('Empty content uri');
    }
    return xml;
  }

  throw UnsupportedError('Unsupported uri scheme: ${uri.scheme}');
}
