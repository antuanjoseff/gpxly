// lib/services/cog_service.dart (Parte 1 de 2)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
import 'package:senda/notifiers/helpers/thresholds.dart';
import 'package:senda/services/altitude_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Convierte el mapa a un JSON de texto para SharedPreferences
  Map<String, dynamic> toJson() => {
    'path': path,
    'minLon': minLon,
    'minLat': minLat,
    'maxLon': maxLon,
    'maxLat': maxLat,
    'width': width,
    'height': height,
    'lastUsed': lastUsed.toIso8601String(),
  };

  // Reconstruye el objeto desde el JSON al abrir la app
  factory CogMap.fromJson(Map<String, dynamic> json) => CogMap(
    path: json['path'],
    minLon: json['minLon'],
    minLat: json['minLat'],
    maxLon: json['maxLon'],
    maxLat: json['maxLat'],
    width: json['width'],
    height: json['height'],
  )..lastUsed = DateTime.parse(json['lastUsed']);
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

  /// 📥 INICIALITZACIÓ CRÍTICA: Restaura els arxius de disc i actualitza el demBoundsProvider al mateix temps
  Future<void> initService(dynamic ref) async {
    final prefs = await SharedPreferences.getInstance();

    final String? cachedJson = prefs.getString('cog_persistent_index');

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _cache.clear();

        for (var item in decoded) {
          final map = CogMap.fromJson(item);
          final file = File(map.path);

          // Solo lo añadimos al índice si el archivo binario realmente existe en el disco
          if (await file.exists()) {
            _cache.add(map);

            // Sincronitzem el demBoundsProvider amb les cèl·les persistides a disc
            ref
                .read(demBoundsProvider.notifier)
                .addCell(map.minLon, map.minLat, map.maxLon, map.maxLat);
          }
        }
        print(
          "💾 [COG] Índex restaurat i mapes de debug sincronitzats: ${_cache.length} fitxers.",
        );
      } catch (e) {
        print("❌ [COG] Error restaurant l'índex: $e");
      }
    }
  }

  /// 💾 DESAR ÍNDEX: Persisteix la llista de metadades a SharedPreferences
  Future<void> _saveIndexToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _cache
        .map((e) => e.toJson())
        .toList();
    await prefs.setString('cog_persistent_index', jsonEncode(jsonList));
  }

  Future<(double, bool)> getCorrectedElevation(
    double lat,
    double lon,
    double gpsAlt,
    dynamic ref,
  ) async {
    // 1. Comprobación rápida en caliente sobre la caché existente
    for (var map in _cache) {
      if (map.contains(lat, lon)) {
        map.lastUsed = DateTime.now();

        // SMART RAM: Si el archivo está en disco pero su RAM fue purgada, lo volvemos a levantar
        if (map.data == null) {
          final file = File(map.path);
          if (await file.exists()) {
            map.data = await file.readAsBytes();
            _optimizeRamUsage(); // Mantenemos la RAM protegida bajo el límite de 4
          } else {
            continue;
          }
        }

        // 🔥 CANVI DE SEGURETAT 1
        final alt = _interpolateElevation(map, lat, lon);
        if (alt != null && alt > 0.0) {
          return (
            alt,
            true,
          ); // Retornem l'altitud del mapa i confirmem que és FIXA (true)
        } else {
          return (
            gpsAlt,
            false,
          ); // Fallback al GPS i avisem que NO és fixa (false) per evitar descalibrar el baròmetre
        }
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
          if (map.data == null) map.data = await File(map.path).readAsBytes();

          // 🔥 CANVI DE SEGURETAT 2
          final alt = _interpolateElevation(map, lat, lon);
          if (alt != null && alt > 0.0) {
            return (alt, true);
          } else {
            return (gpsAlt, false);
          }
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
        if (map.data == null) map.data = await File(map.path).readAsBytes();

        // 🔥 CANVI DE SEGURETAT 3
        final alt = _interpolateElevation(map, lat, lon);
        if (alt != null && alt > 0.0) {
          return (alt, true);
        } else {
          return (gpsAlt, false);
        }
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

    // 🛡️ REFACTORITZACIÓ: Deixem un píxel de marge a les vores per evitar desbordaments de fitxer
    final int x1 = x.floor().clamp(0, map.width - 2);
    final int y1 = y.floor().clamp(0, map.height - 2);
    final int x2 = x1 + 1;
    final int y2 = y1 + 1;

    final double xFrac = x - x1;
    final double yFrac = y - y1;

    double getV(int r, int c) {
      final int offset = (r * map.width + c) * 4;
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

    if (v11 < -1000 || v21 < -1000 || v12 < -1000 || v22 < -1000) {
      AltitudeLoggerService().log(
        "⚠️ COG BIND -> Píxel fora de rang o NoData detectat a la vora del fitxer. Retornant null.",
      );
      return null;
    }

    // Fórmula Bilineal
    final double top = v11 + xFrac * (v21 - v11);
    final double bottom = v12 + xFrac * (v22 - v12);

    final finalElevation = top + yFrac * (bottom - top);

    // 🛡️ SEGONA DEFENSA: Si la fórmula matemàtica dóna zero o negatiu (improbable a Catalunya), evitem retornar-ho
    return finalElevation > 0.0 ? finalElevation : null;
  }

  Future<void> _downloadNewArea(double lat, double lon, dynamic ref) async {
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

        // Mapegem 'x-width' a width, i 'x-height' a height (Evita cotes desalineades)
        final width = int.parse(response.headers['x-width'] ?? "500");
        final height = int.parse(response.headers['x-height'] ?? "500");

        final dir = await getApplicationDocumentsDirectory();
        final path =
            "${dir.path}/elev_${DateTime.now().millisecondsSinceEpoch}.bin";

        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        // 📝 MANTINGUT: El bounding box se queda intacto con sus índices originales [0],[1],[2],[3]
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

        await _managePersistentCache(newMap);
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
      AltitudeLoggerService().log(
        "❌ COG DESCARGA -> Error descarregant cel·la d'Azure: $e",
      );
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // NETEJA DE MEMÒRIA I DISC
  // ───────────────────────────────────────────────

  /// 🧠 GESTIÓ INTEGRADA DE MEMÒRIA I DISC (Límit N basat en TrackThresholds)
  Future<void> _managePersistentCache(CogMap newMap) async {
    _cache.add(newMap);

    // Si superem el límit N d'arxius persistents definits a TrackThresholds
    if (_cache.length > TrackThresholds.maxPersistentFiles) {
      // 1. Ordenem de l'arxiu més antic al més recent segons el seu ús
      _cache.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));

      // 2. Extraiem el que fa més temps que no es fa servir (el primer de la llista)
      final oldest = _cache.removeAt(0);

      // 3. Alliberem immediatament el seu espai a la memòria RAM
      oldest.data = null;

      // 4. Eliminem l'arxiu físic .bin del disc per alliberar espai real al telèfon
      final file = File(oldest.path);
      if (await file.exists()) {
        await file.delete().catchError((e) {
          print("⚠️ No s'ha pogut esborrar el fitxer permanent antic: $e");
        });
        print(
          "🗑️ [COG] S'ha eliminat del disc l'arxiu més antic per superar el límit N.",
        );
      }
    }

    // 5. Mantenemos también controlada la memoria RAM en caliente bajo el límite de 4 celdas
    _optimizeRamUsage();

    // 6. Desem el nou estat de l'índex text de forma persistent
    await _saveIndexToDisk();
  }

  /// 🧠 OPTIMITZACIÓ DE RAM: Libera RAM poniendo el data en null, manteniendo el archivo físico intacto
  void _optimizeRamUsage() {
    final mapsWithData = _cache.where((m) => m.data != null).toList();
    if (mapsWithData.length > _maxCacheSize) {
      mapsWithData.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
      mapsWithData.first.data = null;
      print(
        "🧠 [COG] RAM optimizada: Celda antigua liberada de la memoria física.",
      );
    }
  }

  // ✅ CANVIAT DE NOM: Ara l'alliberament físic queda blindat del tancament efímer de Riverpod
  Future<void> clearAllCacheFiles() async {
    print("🧹 CogService: Netejant memòria cau i fitxers...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cog_persistent_index');

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
