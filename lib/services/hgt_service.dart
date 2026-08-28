import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class HgtService {
  static final HgtService _instance = HgtService._internal();
  factory HgtService() => _instance;
  HgtService._internal();

  static const int srtmSize = 3601;

  RandomAccessFile? _openedFile;
  String? _currentFileName;

  Future<(double, bool)> getCorrectedElevation(
    double lat,
    double lon,
    double gpsAlt,
  ) async {
    final fileName = _getHgtFileName(lat, lon);

    // Si ja tenim el fitxer obert i és el correcte
    if (_currentFileName == fileName && _openedFile != null) {
      final alt = await _readFromOpenedFile(lat, lon, gpsAlt);
      return (alt, true);
    }

    // Obrim el fitxer local
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dem/$fileName');

    if (!await file.exists()) {
      return (gpsAlt, false);
    }

    // Tanquem l’anterior
    await _closeCurrentFile();

    // Obrim el nou
    _openedFile = await file.open();
    _currentFileName = fileName;

    final alt = await _readFromOpenedFile(lat, lon, gpsAlt);
    return (alt, true);
  }

  Future<double> _readFromOpenedFile(
    double lat,
    double lon,
    double gpsAlt,
  ) async {
    try {
      final fLat = lat - lat.floor();
      final fLon = lon - lon.floor();

      final exactRow = (srtmSize - 1) * (1.0 - fLat);
      final exactCol = (srtmSize - 1) * fLon;

      final r0 = exactRow.floor().clamp(0, srtmSize - 1);
      final r1 = (r0 + 1).clamp(0, srtmSize - 1);
      final c0 = exactCol.floor().clamp(0, srtmSize - 1);
      final c1 = (c0 + 1).clamp(0, srtmSize - 1);

      final dr = exactRow - r0;
      final dc = exactCol - c0;

      // Lectura dels 4 vèrtexs de la cel·la de 30m
      int? v00, v01, v10, v11;

      // Fila superior (r0)
      final offset0 = (r0 * srtmSize + c0) * 2;
      await _openedFile!.setPosition(offset0);
      if (c1 == c0 + 1) {
        final bytes0 = await _openedFile!.read(4);
        if (bytes0.length >= 4) {
          final data0 = ByteData.sublistView(bytes0);
          v00 = data0.getInt16(0, Endian.big);
          v01 = data0.getInt16(2, Endian.big);
        }
      } else {
        final bytes0 = await _openedFile!.read(2);
        if (bytes0.length >= 2) {
          v00 = ByteData.sublistView(bytes0).getInt16(0, Endian.big);
          v01 = v00;
        }
      }

      // Fila inferior (r1)
      if (r1 == r0) {
        v10 = v00;
        v11 = v01;
      } else {
        final offset1 = (r1 * srtmSize + c0) * 2;
        await _openedFile!.setPosition(offset1);
        if (c1 == c0 + 1) {
          final bytes1 = await _openedFile!.read(4);
          if (bytes1.length >= 4) {
            final data1 = ByteData.sublistView(bytes1);
            v10 = data1.getInt16(0, Endian.big);
            v11 = data1.getInt16(2, Endian.big);
          }
        } else {
          final bytes1 = await _openedFile!.read(2);
          if (bytes1.length >= 2) {
            v10 = ByteData.sublistView(bytes1).getInt16(0, Endian.big);
            v11 = v10;
          }
        }
      }

      // Interpolació bilineal si els 4 punts tenen dades vàlides
      if (v00 != null &&
          v01 != null &&
          v10 != null &&
          v11 != null &&
          v00 != -32768 &&
          v01 != -32768 &&
          v10 != -32768 &&
          v11 != -32768) {
        final top = v00 * (1.0 - dc) + v01 * dc;
        final bottom = v10 * (1.0 - dc) + v11 * dc;
        return top * (1.0 - dr) + bottom * dr;
      }

      // Fallback si algun vèrtex no té dades vàlides (nodata -32768)
      final valid = [v00, v01, v10, v11]
          .where((v) => v != null && v != -32768)
          .map((v) => v!.toDouble())
          .toList();

      if (valid.isNotEmpty) {
        return valid.reduce((a, b) => a + b) / valid.length;
      }

      return gpsAlt;
    } catch (_) {
      return gpsAlt;
    }
  }

  String _getHgtFileName(double lat, double lon) {
    final latInt = lat.floor();
    final lonInt = lon.floor();

    final ns = latInt >= 0 ? 'N' : 'S';
    final ew = lonInt >= 0 ? 'E' : 'W';

    return '$ns${latInt.abs().toString().padLeft(2, '0')}$ew${lonInt.abs().toString().padLeft(3, '0')}.hgt';
  }

  Future<void> _closeCurrentFile() async {
    await _openedFile?.close();
    _openedFile = null;
    _currentFileName = null;
  }

  Future<void> dispose() async => await _closeCurrentFile();
}
