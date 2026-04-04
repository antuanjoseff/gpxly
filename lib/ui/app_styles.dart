import 'package:flutter/material.dart';

class AppButtons {
  static const Color neonGreen = Color(0xFF00E676);

  // ESTIL ACTIU (Verd Neó)
  static final ButtonStyle active = ElevatedButton.styleFrom(
    backgroundColor: neonGreen,
    foregroundColor: Colors.black,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  // ESTIL INACTIU (Gris)
  static final ButtonStyle inactive = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade800,
    foregroundColor: Colors.white38,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.normal),
  );
}
