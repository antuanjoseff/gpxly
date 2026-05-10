import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class HgtService {
  static const int srtm1Size = 3601; // Resolució 30m (SRTM-1)

  File? _currentFile;
  String? _currentFileName;
  RandomAccessFile? _openedFile;
  final Set<String> _downloadingFiles = {};

  /// Retorna l'altitud corregida o la del GPS si no hi ha dades
  Future<double> getCorrectedElevation(
    double lat,
    double lon,
    double gpsAlt,
  ) async {
    final fileName = _getHgtFileName(lat, lon);

    try {
      if (_currentFileName != fileName) {
        await _closeCurrentFile();
        final file = await _ensureHgtFile(fileName);
        if (file != null) {
          _currentFile = file;
          _currentFileName = fileName;
          _openedFile = await file.open(mode: FileMode.read);
        }
      }

      if (_openedFile == null) return gpsAlt;

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

      if (elevation == -32768) return gpsAlt;

      return elevation.toDouble();
    } catch (e) {
      print("[SENDA-HGT] Error llegint alçada: $e");
      return gpsAlt;
    }
  }

  String _getHgtFileName(double lat, double lon) {
    int latInt = lat.floor();
    int lonInt = lon.floor();
    String latPart =
        "${latInt >= 0 ? 'N' : 'S'}${latInt.abs().toString().padLeft(2, '0')}";
    String lonPart =
        "${lonInt >= 0 ? 'E' : 'W'}${lonInt.abs().toString().padLeft(3, '0')}";
    return "$latPart$lonPart.hgt";
  }

  /// Gestiona la cau (cache) i descàrrega des d'OpenTopography (SDSC S3)
  /// Gestiona la cau (cache) i descàrrega des d'OpenTopography (SDSC S3)
  Future<File?> _ensureHgtFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final hgtDir = Directory('${dir.path}/dem');
    if (!await hgtDir.exists()) await hgtDir.create(recursive: true);

    final file = File('${hgtDir.path}/$fileName');

    // 1. COMPROVACIÓ D'EXISTÈNCIA (Més conservadora)
    if (await file.exists()) {
      int size = await file.length();
      // SRTM1 (30m) ocupa ~25MB, SRTM3 (90m) ocupa ~2.8MB.
      // Posem 2.5MB com a mínim per acceptar qualsevol dels dos formats.
      if (size > 2500000) {
        return file;
      }
      // Si el fitxer és massa petit (corrupte o error d'API anterior), l'esborrem per reintentar
      await file.delete();
    }

    // 2. EVITAR PETICIONS SIMULTÀNIES PER LA MATEIXA RAJOLA
    if (_downloadingFiles.contains(fileName)) {
      print("[SENDA-HGT] ⏳ Ja hi ha una descàrrega en curs per: $fileName");
      return null;
    }

    _downloadingFiles.add(fileName);

    try {
      // Calculem els límits del quadrat segons el nom del fitxer (ex: N41E002)
      int latS =
          int.parse(fileName.substring(1, 3)) *
          (fileName.startsWith('N') ? 1 : -1);
      int lonW =
          int.parse(fileName.substring(4, 7)) *
          (fileName.startsWith('E') ? 1 : -1);

      final String apiKey = "1890b659ee4a822b2f9fceff967e9221";
      // ⚠️ IMPORTANT: L'endpoint ha de ser /API/globaldem
      final url =
          "https://opentopography.org"
          "?demtype=SRTMGL1"
          "&south=$latS"
          "&north=${latS + 1}"
          "&west=$lonW"
          "&east=${lonW + 1}"
          "&outputFormat=HGT"
          "&API_Key=$apiKey";

      print("[SENDA-HGT] 🌐 Iniciant descàrrega API: $fileName");

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        for (final fileInZip in archive) {
          if (fileInZip.name.toLowerCase().endsWith('.hgt')) {
            // 3. ESCRIPTURA SEGURA (Atòmica)
            // Escrivim primer a un fitxer temporal i després el reanomenem.
            // Així evitem que el següent 'get' llegeixi un fitxer incomplet.
            final tempFile = File('${file.path}.tmp');
            await tempFile.writeAsBytes(fileInZip.content as List<int>);
            await tempFile.rename(file.path);

            print(
              "[SENDA-HGT] ✅ GUARDAT I COMPLET: $fileName (${file.lengthSync()} bytes)",
            );
            await _cleanupOldFiles(hgtDir);
            return file;
          }
        }
      } else {
        print(
          "[SENDA-HGT] ❌ Error API (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      print("[SENDA-HGT] ❌ Error en petició API: $e");
    } finally {
      // 4. ALLIBEREM EL BLOQUEIG SEMPRE
      _downloadingFiles.remove(fileName);
    }
    return null;
  }

  Future<void> _cleanupOldFiles(Directory hgtDir) async {
    try {
      List<FileSystemEntity> files = hgtDir
          .listSync()
          .where((f) => f.path.endsWith('.hgt'))
          .toList();

      if (files.length <= 3) return;

      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );

      int toDelete = files.length - 3;
      for (int i = 0; i < toDelete; i++) {
        if (!files[i].path.contains(_currentFileName ?? "")) {
          print(
            "[SENDA-HGT] 🗑️ Alliberant espai: ${files[i].path.split('/').last}",
          );
          await files[i].delete();
        }
      }
    } catch (e) {
      print("[SENDA-HGT] Error en la neteja: $e");
    }
  }

  Future<void> _closeCurrentFile() async {
    await _openedFile?.close();
    _openedFile = null;
    _currentFileName = null;
  }

  Future<void> dispose() async {
    await _closeCurrentFile();
  }
}
