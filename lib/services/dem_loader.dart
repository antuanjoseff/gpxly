import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DemLoader {
  static final List<String> tiles = [
    'N41E002.hgt',
    'N41E003.hgt',
    'N42E002.hgt',
    'N42E003.hgt',
  ];

  static Future<String> getDemDirectoryPath() async {
    final base = await getApplicationDocumentsDirectory();
    return '${base.path}/dem';
  }

  static Future<void> ensureDemFiles() async {
    final demPath = await getDemDirectoryPath();
    final demDir = Directory(demPath);
    print("DEM loaded at: $demPath");

    if (!await demDir.exists()) {
      await demDir.create(recursive: true);
    }

    for (final tile in tiles) {
      final destFile = File('$demPath/$tile');

      if (!await destFile.exists()) {
        final data = await rootBundle.load('assets/dem/$tile');
        await destFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
    }
  }
}
