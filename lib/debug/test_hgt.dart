import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:senda/services/hgt_service.dart';

class HgtDebugTest {
  static Future<void> run() async {
    print("=== TEST HGT ===");

    final hgt = HgtService();

    // Exemple: Girona Catedral
    final double lat = 41.9872;
    final double lon = 2.8249;
    final double gpsAlt = 0.0; // no importa

    final (alt, fixed) = await hgt.getCorrectedElevation(lat, lon, gpsAlt);

    print("Coordenades: $lat, $lon");
    print("Altitud HGT: $alt");
    print("Corregida: $fixed");

    // Comprovem que el fitxer existeix
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "N41E002.hgt"; // Girona cau dins aquest tile
    final file = File("${dir.path}/dem/$fileName");

    print("Fitxer existeix? ${await file.exists()}");
    print("Mida: ${await file.length()} bytes");

    print("=== FI TEST HGT ===");
  }
}
