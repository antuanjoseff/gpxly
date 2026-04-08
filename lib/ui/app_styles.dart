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

  static final ButtonStyle dialogBase = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 0,
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
  );

  // ⭐ NOU: MÈTODE PER CREAR BOTONS DE DIÀLEG AMB COLOR PERSONALITZAT
  static ButtonStyle dialog(Color background) {
    return dialogBase.merge(
      ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
      ),
    );
  }
}
