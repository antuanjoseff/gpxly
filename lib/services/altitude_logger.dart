import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AltitudeLoggerService {
  static final AltitudeLoggerService _instance =
      AltitudeLoggerService._internal();
  factory AltitudeLoggerService() => _instance;
  AltitudeLoggerService._internal();

  static const String _prefDebugKey = 'gps_debug_enabled';
  bool? _debugEnabledCache;

  Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/altitude_debug.txt');
  }

  Future<bool> isDebugEnabled() async {
    if (_debugEnabledCache != null) return _debugEnabledCache!;
    final prefs = await SharedPreferences.getInstance();
    _debugEnabledCache = prefs.getBool(_prefDebugKey) ?? false;
    return _debugEnabledCache!;
  }

  Future<void> setDebugEnabled(bool enabled) async {
    _debugEnabledCache = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDebugKey, enabled);
  }

  /// 📝 Afegeix una línia de text al log amb la marca de temps actual
  Future<void> log(String message) async {
    try {
      if (!await isDebugEnabled()) return;
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
  Future<bool> shareLog() async {
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
                'Telemetry Log - STrack Rec Altituds', // O subject: '...' si l'enviaries per Email
          ),
        );
        return true;
      }
      await file.writeAsString('[INFO] Log creat automàticament.\n');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Telemetry Log - STrack Rec Altituds',
        ),
      );
      return true;
    } catch (e) {
      print("❌ Error compartint l'arxiu de log: $e");
      return false;
    }
  }
}
