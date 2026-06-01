import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AltitudeLoggerService {
  static final AltitudeLoggerService _instance =
      AltitudeLoggerService._internal();
  factory AltitudeLoggerService() => _instance;
  AltitudeLoggerService._internal();

  Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/altitude_debug.txt');
  }

  /// 📝 Afegeix una línia de text al log amb la marca de temps actual
  Future<void> log(String message) async {
    try {
      final file = await _logFile;
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('T')
          .last
          .substring(0, 8);
      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      print("❌ Error escrivint al log d'altitud: $e");
    }
  }

  /// 🧹 Esborra el contingut de l'arxiu (Reset)
  Future<void> clearLog() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.writeAsString(''); // El deixem buit
      }
    } catch (e) {
      print("❌ Error en fer reset al log: $e");
    }
  }

  /// 📤 Comparteix l'arxiu de text usant el menú natiu del mòbil
  Future<void> shareLog() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        final size = await file.length();
        if (size == 0) {
          await file.writeAsString('[INFO] Log buit inicialitzat.\n');
        }

        // 🚀 SINTAXI OFICIAL ACTUAL: Sense mètodes estàtics ni paràmetres deprecats
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text:
                'Telemetry Log - Senda Altituds', // O subject: '...' si l'enviaries per Email
          ),
        );
      }
    } catch (e) {
      print("❌ Error compartint l'arxiu de log: $e");
    }
  }
}
