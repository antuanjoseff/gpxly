// lib/services/offline_maps_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'elevations_api_conf.dart';

/// Callback de progrés de descàrrega: (bytesRebuts, bytesTotals o null si desconegut)
typedef OfflineDownloadProgress = void Function(int received, int? total);

/// Servei de mapes offline: descàrrega de fitxers .mbtiles i del paquet
/// de glyphs (fonts PBF) compartit per totes les regions.
///
/// Estructura al dispositiu (getApplicationDocumentsDirectory):
///   <docs>/offline_maps/<regio>.mbtiles
///   <docs>/glyphs/<fontstack>/<start>-<end>.pbf
class OfflineMapsService {
  OfflineMapsService._();
  static final OfflineMapsService instance = OfflineMapsService._();

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
  // DESCÀRREGA DE REGIÓ (.mbtiles)
  // ───────────────────────────────────────────────

  /// Descarrega el fitxer .mbtiles de [regio] en streaming.
  /// Llença Exception si el servidor respon amb error.
  Future<File> downloadRegion(
    String regio, {
    OfflineDownloadProgress? onProgress,
  }) async {
    final uri = Uri.https(
      ApiConfig.cogApiHost,
      '${ApiConfig.offlineMapsPath}/${regio.toLowerCase()}',
    );
    debugPrint('⬇️ [OFFLINE] Descarregant regió: $uri');

    final client = http.Client();
    IOSink? sink;
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
      final tmpFile = File('${(await _regionFile(regio)).path}.part');
      sink = tmpFile.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
      sink = null;

      // Renombrem de forma atòmica: mai queda un .mbtiles a mitges
      final finalFile = await _regionFile(regio);
      await tmpFile.rename(finalFile.path);
      debugPrint(
        '✅ [OFFLINE] Regió "$regio" desada (${received ~/ 1024} KB) a ${finalFile.path}',
      );
      return finalFile;
    } catch (e) {
      debugPrint('💥 [OFFLINE] Error descarregant regió "$regio": $e');
      // Neteja del fitxer parcial si n'hi ha
      try {
        await sink?.close();
        final tmp = File('${(await _regionFile(regio)).path}.part');
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }

  // ───────────────────────────────────────────────
  // GLYPHS (una sola vegada, compartits per totes les regions)
  // ───────────────────────────────────────────────

  /// Garanteix que els glyphs estan descomprimits al dispositiu.
  /// Si ja hi són, no fa res. Si no, baixa el zip del servidor i el descomprimeix.
  Future<void> ensureGlyphs({OfflineDownloadProgress? onProgress}) async {
    if (await areGlyphsReady()) return;

    final uri = Uri.https(
      ApiConfig.cogApiHost,
      '${ApiConfig.offlineMapsPath}/glyphs',
    );
    debugPrint('⬇️ [OFFLINE] Descarregant glyphs: $uri');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Error ${response.statusCode} descarregant els glyphs: ${response.body}',
      );
    }
    onProgress?.call(response.bodyBytes.length, response.bodyBytes.length);

    final glyphsPath = await glyphsDir();
    if (!await glyphsPath.exists()) await glyphsPath.create(recursive: true);

    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
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

  // ───────────────────────────────────────────────
  // ESTIL OFFLINE (generat en runtime amb rutes reals)
  // ───────────────────────────────────────────────

  /// Genera el JSON d'estil que fa servir el mbtiles local i els glyphs locals.
  /// Carrega l'estil OSM Bright de assets i li canvia el source/glyphs.
  /// Retorna null si la regió o els glyphs no estan disponibles.
  Future<String?> buildOfflineStyle(String regio) async {
    final downloaded = await isRegionDownloaded(regio);
    final glyphsOk = await areGlyphsReady();
    debugPrint(
      '🗺️ [OFFLINE STYLE] isRegionDownloaded=$downloaded areGlyphsReady=$glyphsOk',
    );
    if (!downloaded) return null;
    if (!glyphsOk) return null;

    final mbtilesPath = (await _regionFile(regio)).path;
    final glyphsPath = (await glyphsDir()).path;
    debugPrint(
      '🗺️ [OFFLINE STYLE] mbtiles=mbtiles://$mbtilesPath glyphs=file://$glyphsPath',
    );

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
    final Map<String, dynamic> style = jsonDecode(styleJson);

    // Substitueix el source pel mbtiles local
    style['sources'] = {
      'openmaptiles': {'type': 'vector', 'url': 'mbtiles://$mbtilesPath'},
    };

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
