// lib/services/offline_maps_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/offline_map_region.dart';
import 'elevations_api_conf.dart';

/// Callback de progrés de descàrrega: (bytesRebuts, bytesTotals o null si desconegut)
typedef OfflineDownloadProgress = void Function(int received, int? total);

class GeofabrikRegion {
  final String id;
  final String name;
  final String pbfUrl;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const GeofabrikRegion({
    required this.id,
    required this.name,
    required this.pbfUrl,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });

  factory GeofabrikRegion.fromFeature(Map<String, dynamic> feature) {
    final properties =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final urls = (properties['urls'] as Map?)?.cast<String, dynamic>() ?? {};
    final bbox = (feature['bbox'] as List).cast<num>();
    return GeofabrikRegion(
      id: properties['id'].toString(),
      name: properties['name'].toString(),
      pbfUrl: urls['pbf'].toString(),
      minLon: bbox[0].toDouble(),
      minLat: bbox[1].toDouble(),
      maxLon: bbox[2].toDouble(),
      maxLat: bbox[3].toDouble(),
    );
  }
}

/// Servei de mapes offline: descàrrega de fitxers .mbtiles i del paquet
/// de glyphs (fonts PBF) compartit per totes les regions.
///
/// Estructura al dispositiu (getApplicationDocumentsDirectory):
///   <docs>/offline_maps/<regio>.mbtiles
///   <docs>/glyphs/<fontstack>/<start>-<end>.pbf
class OfflineMapsService {
  OfflineMapsService._();
  static final OfflineMapsService instance = OfflineMapsService._();

  final Map<String, http.Client> _activeDownloadClients = {};
  final Set<String> _cancelledDownloads = {};

  void cancelRegionDownload(String regio) {
    final client = _activeDownloadClients[regio];
    if (client == null) return;
    _cancelledDownloads.add(regio);
    client.close();
  }

  // ───────────────────────────────────────────────
  // RUTES LOCALS
  // ───────────────────────────────────────────────

  Future<Directory> _offlineMapsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_maps');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> glyphsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/glyphs');
  }

  Future<Directory> spritesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/sprites');
  }

  /// Copia l'sprite inclòs a assets/sprites/ al disc (cal perquè MapLibre
  /// només pot llegir fitxers del sistema, no assets de Flutter).
  /// Copia també la variant @2x: en dispositius amb pixelRatio > 1 MapLibre
  /// Native la demana automàticament i, si no existeix, l'sprite sencer
  /// falla en silenci i les icones no es dibuixen mai en mode offline.
  Future<bool> ensureSprites() async {
    try {
      final dir = await spritesDir();
      if (!await dir.exists()) await dir.create(recursive: true);
      await _copyAssetIfMissing(dir, 'sprite.png');
      await _copyAssetIfMissing(dir, 'sprite.json');
      await _copyAssetIfMissing(dir, 'sprite@2x.png');
      await _copyAssetIfMissing(dir, 'sprite@2x.json');
      final png = File('${dir.path}/sprite.png');
      final json = File('${dir.path}/sprite.json');
      return await png.exists() && await json.exists();
    } catch (e) {
      debugPrint('⚠️ [OFFLINE STYLE] Error copiant sprites: $e');
      return false;
    }
  }

  Future<void> _copyAssetIfMissing(Directory dir, String fileName) async {
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) return;
    try {
      final data = await rootBundle.load('assets/sprites/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('⚠️ [OFFLINE STYLE] No he pogut copiar $fileName: $e');
    }
  }

  Future<File> _regionFile(String regio) async {
    final dir = await _offlineMapsDir();
    return File('${dir.path}/${regio.toLowerCase()}.mbtiles');
  }

  // ───────────────────────────────────────────────
  // ESTAT
  // ───────────────────────────────────────────────

  Future<bool> isRegionDownloaded(String regio) async {
    final f = await _regionFile(regio);
    if (!await f.exists()) return false;
    return await f.length() > 0;
  }

  Future<DateTime?> regionLastModified(String regio) async {
    final file = await _regionFile(regio);
    if (!await file.exists()) return null;
    return file.lastModified();
  }

  Future<bool> areGlyphsReady() async {
    final dir = await glyphsDir();
    if (!await dir.exists()) return false;
    // Comprovació ràpida: hi ha algun .pbf dins algun fontstack
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pbf')) return true;
    }
    return false;
  }

  Future<void> deleteRegion(String regio) async {
    final f = await _regionFile(regio);
    if (await f.exists()) await f.delete();
  }

  // ───────────────────────────────────────────────
  // REGIONS DISPONIBLES (bounding boxes al servidor)
  // ───────────────────────────────────────────────

  /// Obté la llista de regions (.mbtiles) disponibles al servidor amb el
  /// seu bounding box, a partir de `api/mapes/bounds.geojson`.
  Future<List<OfflineMapRegion>> fetchAvailableRegions() async {
    final uri = Uri.https(ApiConfig.cogApiHost, ApiConfig.mapesBoundsPath);
    debugPrint('🌍 [OFFLINE] Obtenint regions disponibles: $uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Error ${response.statusCode} obtenint les regions disponibles: ${response.body}',
      );
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final features = (data['features'] as List).cast<Map<String, dynamic>>();
    return features.map(OfflineMapRegion.fromFeature).toList();
  }

  Future<List<GeofabrikRegion>> fetchGeofabrikRegions() async {
    final uri = Uri.https(ApiConfig.cogApiHost, '/api/geofabrik/regions', {
      '_': DateTime.now().microsecondsSinceEpoch.toString(),
    });
    debugPrint('🌍 [OFFLINE] Obtenint regions Geofabrik: $uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Error ${response.statusCode} obtenint les regions Geofabrik',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (data['features'] as List).cast<Map<String, dynamic>>();
    return features
        .where((feature) {
          final properties = feature['properties'] as Map?;
          final urls = properties?['urls'] as Map?;
          return feature['bbox'] is List &&
              properties?['name'] != null &&
              urls?['pbf'] is String;
        })
        .map(GeofabrikRegion.fromFeature)
        .toList();
  }

  Future<String> requestNewRegion({
    required String name,
    required String url,
    required String email,
    required String lang,
  }) async {
    final uri = Uri.https(ApiConfig.cogApiHost, '/api/mapes/requests');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'url': url,
        'email': email,
        'lang': lang,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error ${response.statusCode} enviant la petició: ${response.body}',
      );
    }
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map && payload['message'] is String) {
        return payload['message'] as String;
      }
    } on FormatException {
      return response.body;
    }
    return response.body;
  }

  // ───────────────────────────────────────────────
  // DESCÀRREGA DE REGIÓ (.mbtiles)
  // ───────────────────────────────────────────────

  /// Descarrega el fitxer .mbtiles de [regio] en streaming.
  /// Llença Exception si el servidor respon amb error.
  Future<File?> downloadRegion(
    String regio, {
    OfflineDownloadProgress? onProgress,
  }) async {
    final uri = Uri.https(
      ApiConfig.cogApiHost,
      '${ApiConfig.offlineMapsPath}/${regio.toLowerCase()}',
    );
    debugPrint('⬇️ [OFFLINE] Descarregant regió: $uri');

    final client = http.Client();
    _cancelledDownloads.remove(regio);
    _activeDownloadClients[regio] = client;
    IOSink? sink;
    File? tmpFile;
    try {
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception(
          'Error ${response.statusCode} descarregant la regió: $body',
        );
      }

      final total = response.contentLength;
      tmpFile = File('${(await _regionFile(regio)).path}.part');
      sink = tmpFile.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
      sink = null;

      if (_cancelledDownloads.remove(regio)) {
        if (await tmpFile.exists()) await tmpFile.delete();
        return null;
      }

      // Renombrem de forma atòmica: mai queda un .mbtiles a mitges
      final finalFile = await _regionFile(regio);
      await tmpFile.rename(finalFile.path);
      if (_cancelledDownloads.remove(regio)) {
        if (await finalFile.exists()) await finalFile.delete();
        return null;
      }
      debugPrint(
        '✅ [OFFLINE] Regió "$regio" desada (${received ~/ 1024} KB) a ${finalFile.path}',
      );
      return finalFile;
    } catch (e) {
      debugPrint('💥 [OFFLINE] Error descarregant regió "$regio": $e');
      // Neteja del fitxer parcial si n'hi ha
      try {
        await sink?.close();
        final partialFile =
            tmpFile ?? File('${(await _regionFile(regio)).path}.part');
        if (await partialFile.exists()) await partialFile.delete();
      } catch (_) {}
      if (_cancelledDownloads.remove(regio)) return null;
      rethrow;
    } finally {
      if (identical(_activeDownloadClients[regio], client)) {
        _activeDownloadClients.remove(regio);
      }
      _cancelledDownloads.remove(regio);
      client.close();
    }
  }

  // ───────────────────────────────────────────────
  // GLYPHS (una sola vegada, compartits per totes les regions)
  // ───────────────────────────────────────────────

  /// Garanteix que els glyphs inclosos a assets estan descomprimits al dispositiu.
  Future<void> ensureGlyphs({OfflineDownloadProgress? onProgress}) async {
    if (await areGlyphsReady()) return;

    debugPrint('📦 [MAP STYLE] Descomprimint glyphs inclosos als assets');
    final data = await rootBundle.load('assets/glyphs.zip');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    onProgress?.call(bytes.length, bytes.length);

    final glyphsPath = await glyphsDir();
    if (!await glyphsPath.exists()) await glyphsPath.create(recursive: true);

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      final outPath = '${glyphsPath.path}/${entry.name}';
      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      }
    }
    debugPrint('✅ [OFFLINE] Glyphs descomprimits a ${glyphsPath.path}');
  }

  /// Retorna l'estil online amb els glyphs del bundle disponibles localment.
  Future<String> buildOnlineStyle() async {
    await ensureGlyphs();
    final styleJson = await rootBundle.loadString('assets/osm_style.json');
    final style = jsonDecode(styleJson) as Map<String, dynamic>;
    final glyphsPath = (await glyphsDir()).path;
    style['glyphs'] = 'file://$glyphsPath/{fontstack}/{range}.pbf';
    return jsonEncode(style);
  }

  // ───────────────────────────────────────────────
  // ESTIL OFFLINE (generat en runtime amb rutes reals)
  // ───────────────────────────────────────────────

  /// Genera el JSON d'estil que fa servir els mbtiles locals de totes les
  /// [regions] descarregades i els glyphs locals. Cada regió aporta el seu
  /// propi source vectorial; les capes de l'estil OSM Bright es dupliquen
  /// per cada source perquè totes es pintin simultàniament.
  /// Carrega l'estil OSM Bright de assets i li canvia el source/glyphs.
  /// Retorna null si no hi ha cap regió disponible.
  Future<String?> buildOfflineStyle(List<String> regions) async {
    await ensureGlyphs();
    final glyphsOk = await areGlyphsReady();
    final downloadedRegions = <String>[];
    for (final regio in regions) {
      if (await isRegionDownloaded(regio)) downloadedRegions.add(regio);
    }
    debugPrint(
      '🗺️ [OFFLINE STYLE] regionsDescarregades=$downloadedRegions areGlyphsReady=$glyphsOk',
    );
    if (downloadedRegions.isEmpty) return null;
    if (!glyphsOk) return null;

    final glyphsPath = (await glyphsDir()).path;

    // Diagnòstic: llista els fontstacks realment disponibles. L'estil demana
    // "Noto Sans Regular/Bold/Italic" — si aquí no hi són, els topònims
    // que els fan servir no es pintaran.
    try {
      final stacks = await Directory(glyphsPath)
          .list()
          .where((e) => e is Directory)
          .map((e) => e.path.split('/').last)
          .toList();
      debugPrint('🔤 [OFFLINE STYLE] Fontstacks disponibles: $stacks');
    } catch (e) {
      debugPrint('⚠️ [OFFLINE STYLE] No he pogut llistar fontstacks: $e');
    }

    // Carrega l'estil OSM Bright base des de assets
    final styleJson = await rootBundle.loadString(
      'assets/osm_bright_offline.json',
    );
    final Map<String, dynamic> baseStyle = jsonDecode(styleJson);
    final baseLayers = (baseStyle['layers'] as List)
        .cast<Map<String, dynamic>>();

    final sources = <String, dynamic>{};
    final layers = <Map<String, dynamic>>[];
    for (var i = 0; i < downloadedRegions.length; i++) {
      final regio = downloadedRegions[i];
      final sourceId = 'openmaptiles_$regio';
      final mbtilesPath = (await _regionFile(regio)).path;
      sources[sourceId] = {'type': 'vector', 'url': 'mbtiles://$mbtilesPath'};
      debugPrint('🗺️ [OFFLINE STYLE] $sourceId=mbtiles://$mbtilesPath');

      for (final layer in baseLayers) {
        if (layer['source'] == null) {
          // Capes sense source (p.ex. "background"): només un cop.
          if (i == 0) layers.add(layer);
          continue;
        }
        final dup = Map<String, dynamic>.from(layer);
        dup['id'] = '${layer['id']}_$regio';
        dup['source'] = sourceId;
        layers.add(dup);
      }
    }

    final Map<String, dynamic> style = Map<String, dynamic>.from(baseStyle);
    style['sources'] = sources;
    style['layers'] = layers;

    // Substitueix glyphs pels locals
    style['glyphs'] = 'file://$glyphsPath/{fontstack}/{range}.pbf';

    // Sprite local: el copia del bundle si cal i l'apunta; si falla, el treu
    final spritesOk = await ensureSprites();
    if (spritesOk) {
      final spritesPath = (await spritesDir()).path;
      // MapLibre vol esquema file:// per als sprites locals
      style['sprite'] = 'file://$spritesPath/sprite';
      debugPrint('🖼️ [OFFLINE STYLE] Sprite=file://$spritesPath/sprite');
    } else {
      style.remove('sprite');
    }

    return jsonEncode(style);
  }
}
