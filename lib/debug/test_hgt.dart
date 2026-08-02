import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:strack_rec/services/hgt_service.dart';

class HgtDebugTest {
  static Future<void> run() async {
    print("=== TEST HGT ===");

    final hgt = HgtService();

    // Exemple: Girona Catedral
    const double lat = 41.9872;
    const double lon = 2.8249;
    const double gpsAlt = 0.0; // no importa

    final (alt, fixed) = await hgt.getCorrectedElevation(lat, lon, gpsAlt);

    print("Coordenades: $lat, $lon");
    print("Altitud HGT: $alt");
    print("Corregida: $fixed");

    // Comprovem que el fitxer existeix
    final dir = await getApplicationDocumentsDirectory();
    const fileName = "N41E002.hgt"; // Girona cau dins aquest tile
    final file = File("${dir.path}/dem/$fileName");

    print("Fitxer existeix? ${await file.exists()}");
    print("Mida: ${await file.length()} bytes");

    print("=== FI TEST HGT ===");
  }
}
