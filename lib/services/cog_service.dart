// lib/services/cog_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';

class CogMap {
  final String path;
  final double minLon, minLat, maxLon, maxLat;
  final int width, height;
  DateTime lastUsed;
  Uint8List? data; // 🧠 Millora: Dades en memòria

  CogMap({
    required this.path,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.width,
    required this.height,
    this.data,
  }) : lastUsed = DateTime.now();

  bool contains(double lat, double lon) =>
      (lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon);
}

class CogService {
  static final CogService _instance = CogService._internal();
  factory CogService() => _instance;
  CogService._internal();

  final List<CogMap> _cache = [];
  final int _maxCacheSize = 4;

  DateTime? _lastFailedDownload;
  final Duration _retryInterval = const Duration(minutes: 5);
  Future<void>? _activeDownload;

  // GETTER: Exposem la llista de celdas actuals en memòria cau per poder dibuixar els seus bounds
  List<CogMap> get activeCacheMaps => List.unmodifiable(_cache);

  // 🔥 CORREGIDO: Añadimos 'Ref ref' en los parámetros de la cabecera
  Future<(double, bool)> getCorrectedElevation(
    double lat,
    double lon,
    double gpsAlt,
    Ref ref,
  ) async {
    // 1. Comprobación rápida en caliente sobre la caché existente
    for (var map in _cache) {
      if (map.contains(lat, lon)) {
        map.lastUsed = DateTime.now();
        final alt = _interpolateElevation(map, lat, lon);
        return (alt ?? gpsAlt, true);
      }
    }

    // 2. Freno de mano si el servidor falló recientemente
    if (_lastFailedDownload != null &&
        DateTime.now().difference(_lastFailedDownload!) < _retryInterval) {
      return (gpsAlt, false);
    }

    // 3. Si hay otra descarga en curso, esperamos a que termine esa tarea específica.
    final currentDownload = _activeDownload;
    if (currentDownload != null) {
      await currentDownload.catchError((_) {});

      // Volvemos a mirar la caché tras la espera sin invocar recursión
      for (var map in _cache) {
        if (map.contains(lat, lon)) {
          map.lastUsed = DateTime.now();
          final alt = _interpolateElevation(map, lat, lon);
          return (alt ?? gpsAlt, true);
        }
      }
      return (gpsAlt, false);
    }

    // 4. Si no había descarga, somos los encargados de iniciarla pasando el ref
    _activeDownload = _downloadNewArea(lat, lon, ref);
    try {
      await _activeDownload;
    } catch (e) {
      print("❌ [COG SERVICE] Error en la descarga: $e");
    } finally {
      _activeDownload = null; // Liberación garantizada
    }

    // 5. Verificación final post-descarga
    for (var map in _cache) {
      if (map.contains(lat, lon)) {
        final alt = _interpolateElevation(map, lat, lon);
        return (alt ?? gpsAlt, true);
      }
    }

    return (gpsAlt, false);
  }

  // 📐 INTERPOLACIÓ BILINEAL: Calcula l'altura exacta entre 4 píxels
  double? _interpolateElevation(CogMap map, double lat, double lon) {
    if (map.data == null) return null;

    final double x =
        ((lon - map.minLon) / (map.maxLon - map.minLon)) * (map.width - 1);
    final double y =
        ((map.maxLat - lat) / (map.maxLat - map.minLat)) * (map.height - 1);

    final int x1 = x.floor().clamp(0, map.width - 1);
    final int y1 = y.floor().clamp(0, map.height - 1);
    final int x2 = (x1 + 1).clamp(0, map.width - 1);
    final int y2 = (y1 + 1).clamp(0, map.height - 1);

    final double xFrac = x - x1;
    final double yFrac = y - y1;

    double getV(int r, int c) {
      final int offset = (r * map.width + c) * 4;
      // Blindatge de seguretat contra desbordament de llista
      if (offset < 0 || offset + 4 > map.data!.length) return -9999;
      return ByteData.sublistView(
        map.data!,
        offset,
        offset + 4,
      ).getFloat32(0, Endian.little);
    }

    final v11 = getV(y1, x1);
    final v21 = getV(y1, x2);
    final v12 = getV(y2, x1);
    final v22 = getV(y2, x2);

    if (v11 < -1000 || v21 < -1000 || v12 < -1000 || v22 < -1000) return null;

    // Fórmula Bilineal
    final double top = v11 + xFrac * (v21 - v11);
    final double bottom = v12 + xFrac * (v22 - v12);
    return top + yFrac * (bottom - top);
  }

  Future<void> _downloadNewArea(double lat, double lon, Ref ref) async {
    final uri = Uri.https(
      'cog-tiles-euaeg7eaavbqczgf.spaincentral-01.azurewebsites.net',
      '/api/getTile',
      {'lat': lat.toString(), 'lon': lon.toString(), 'buf': '0.07'},
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final bbox = response.headers['x-bbox']!
            .split(',')
            .map(double.parse)
            .toList();

        // ✅ CORREGIT: Mapegem 'x-width' a width, i 'x-height' a height (Evita cotes desalineades)
        final width = int.parse(response.headers['x-width'] ?? "500");
        final height = int.parse(response.headers['x-height'] ?? "500");

        final dir = await getApplicationDocumentsDirectory();
        final path =
            "${dir.path}/elev_${DateTime.now().millisecondsSinceEpoch}.bin";

        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        // 📝 MANTINGUT: El bounding box es queda intacte com el tenies originalment
        final newMap = CogMap(
          path: path,
          minLon: bbox[0],
          minLat: bbox[1],
          maxLon: bbox[2],
          maxLat: bbox[3],
          width: width,
          height: height,
          data: response.bodyBytes, // 🚀 Guardem directament en RAM
        );

        _manageCache(newMap);
        _lastFailedDownload = null;
        ref
            .read(demBoundsProvider.notifier)
            .addCell(
              bbox[0], // minLon
              bbox[1], // minLat
              bbox[2], // maxLon
              bbox[3], // maxLat
            );
      }
    } catch (e) {
      _lastFailedDownload = DateTime.now();
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // NETEJA DE MEMÒRIA I DISC
  // ───────────────────────────────────────────────

  void _manageCache(CogMap newMap) {
    if (_cache.length >= _maxCacheSize) {
      _cache.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));

      final oldest = _cache.removeAt(0);

      // Alliberem la RAM immediatament
      oldest.data = null;

      // Esborrem el fitxer físic
      File(oldest.path).delete().catchError((e) {
        print("⚠️ No s'ha pogut esborrar el fitxer temporal: $e");
      });
    }
    _cache.add(newMap);
  }

  // ✅ CANVIAT DE NOM: Ara l'alliberament físic queda blindat del tancament efímer de Riverpod
  Future<void> clearAllCacheFiles() async {
    print("🧹 CogService: Netejant memòria cau i fitxers...");
    for (var map in _cache) {
      map.data = null; // Allibera RAM
      final file = File(map.path);
      if (await file.exists()) {
        await file.delete().catchError((_) {});
      }
    }
    _cache.clear();
  }
}
