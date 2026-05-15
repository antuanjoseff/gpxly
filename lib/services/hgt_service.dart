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

      final row = (srtmSize - 1) - (fLat * (srtmSize - 1)).round();
      final col = (fLon * (srtmSize - 1)).round();

      final offset = (row * srtmSize + col) * 2;

      await _openedFile!.setPosition(offset);
      final bytes = await _openedFile!.read(2);

      if (bytes.length < 2) return gpsAlt;

      final data = ByteData.sublistView(bytes);
      final elevation = data.getInt16(0, Endian.big);

      return elevation == -32768 ? gpsAlt : elevation.toDouble();
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
