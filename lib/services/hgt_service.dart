import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class HgtService {
  // singleton clàssic: instància única i persistent
  static final HgtService _instance = HgtService._internal();
  factory HgtService() => _instance;
  HgtService._internal();

  static const int srtm1Size = 3601;
  final Set<String> _downloadingFiles = {};

  File? _currentFile;
  String? _currentFileName;
  RandomAccessFile? _openedFile;

  /// Retorna l'altitud corregida (si el fitxer existeix) o la del GPS (si no hi és).
  /// Si el fitxer no existeix, inicia la descàrrega en segon pla sense bloquejar.
  /// Retorna una parella de valors: (Alçada, EstàCorregida)
  /// Si el fitxer existeix, retorna (AlçadaHGT, true)
  /// Si no existeix, retorna (AlçadaGPS, false)
  // hgt_service.dart

  Future<(double, bool)> getCorrectedElevation(
    double lat,
    double lon,
    double gpsAlt,
  ) async {
    final fileName = _getHgtFileName(lat, lon);

    // 1. Memòria ràpida (fitxer obert)
    if (_currentFileName == fileName && _openedFile != null) {
      final alt = await _readFromOpenedFile(lat, lon, gpsAlt);
      return (alt, true);
    }

    // 2. BLOQUEIG IMMEDIAT (Síncron)
    if (_downloadingFiles.contains(fileName)) {
      return (gpsAlt, false);
    }

    // Comprovem si el fitxer ja existeix al disc
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dem/$fileName');

    if (await file.exists() && await file.length() > 2500000) {
      // Si existeix, no fem res aquí, s'obrirà a la següent crida del GPS
      return (gpsAlt, false);
    }

    // Si no el tenim, bloquegem i demanem
    _downloadingFiles.add(fileName); // Marquem com a "en curs"
    _ensureHgtFileInBackground(fileName);

    return (gpsAlt, false);
  }

  // --- LÒGICA DE LECTURA ---
  Future<double> _readFromOpenedFile(
    double lat,
    double lon,
    double gpsAlt,
  ) async {
    try {
      double fLat = lat - lat.floor();
      double fLon = lon - lon.floor();
      int row = (srtm1Size - 1) - (fLat * (srtm1Size - 1)).round();
      int col = (fLon * (srtm1Size - 1)).round();
      int offset = (row * srtm1Size + col) * 2;

      await _openedFile!.setPosition(offset);
      final bytes = await _openedFile!.read(2);
      if (bytes.length < 2) return gpsAlt;

      final data = ByteData.sublistView(bytes);
      int elevation = data.getInt16(0, Endian.big);
      return (elevation == -32768) ? gpsAlt : elevation.toDouble();
    } catch (_) {
      return gpsAlt;
    }
  }

  // --- LÒGICA DE DESCÀRREGA (EN SEGON PLA) ---
  Future<void> _ensureHgtFileInBackground(String fileName) async {
    if (_downloadingFiles.contains(fileName)) return;

    final dir = await getApplicationDocumentsDirectory();
    final hgtDir = Directory('${dir.path}/dem');
    if (!await hgtDir.exists()) await hgtDir.create(recursive: true);
    final file = File('${hgtDir.path}/$fileName');

    _downloadingFiles.add(fileName);

    try {
      // 1. EXTRACCIÓ CORRECTA (N41E002)
      // fileName.substring(4, 7) per a "002"
      int latS =
          int.parse(fileName.substring(1, 3)) *
          (fileName.startsWith('N') ? 1 : -1);
      int lonW =
          int.parse(fileName.substring(4, 7)) *
          (fileName.substring(3, 4) == 'E' ? 1 : -1);

      // 2. URL CORRECTA (Afegim /api/globaldem i paràmetres nets)
      final urlString =
          "https://portal.opentopography.org/API/globaldem"
          "?demtype=SRTMGL1"
          "&south=$latS"
          "&north=${latS + 1}"
          "&west=$lonW"
          "&east=${lonW + 1}"
          "&outputFormat=HGT"
          "&API_Key=1890b659ee4a822b2f9fceff967e9221";

      print("[SENDA-HGT] 🌐 Petició REAL a: $urlString");

      final response = await http
          .get(Uri.parse(urlString))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        // Si l'API respon OK, processem el ZIP
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        for (final fileInZip in archive) {
          if (fileInZip.name.toLowerCase().endsWith('.hgt')) {
            final tempFile = File('${file.path}.tmp');
            await tempFile.writeAsBytes(fileInZip.content as List<int>);
            await tempFile.rename(file.path);
            print("[SENDA-HGT] ✅ FITXER LLERT: $fileName");
            return;
          }
        }
      } else {
        print(
          "[SENDA-HGT] ❌ Error API (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      print("[SENDA-HGT] ❌ Error xarxa: $e");
    } finally {
      _downloadingFiles.remove(fileName);
    }
  }

  // --- AUXILIARS ---
  Future<File?> _getExistingFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dem/$fileName');
    if (await file.exists() && await file.length() > 2500000) return file;
    return null;
  }

  String _getHgtFileName(double lat, double lon) {
    int latInt = lat.floor();
    int lonInt = lon.floor();
    return "${latInt >= 0 ? 'N' : 'S'}${latInt.abs().toString().padLeft(2, '0')}${lonInt >= 0 ? 'E' : 'W'}${lonInt.abs().toString().padLeft(3, '0')}.hgt";
  }

  Future<void> _closeCurrentFile() async {
    await _openedFile?.close();
    _openedFile = null;
    _currentFileName = null;
  }

  Future<void> dispose() async => await _closeCurrentFile();
}
