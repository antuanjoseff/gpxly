import 'package:flutter/material.dart';

class AppMessages {
  // Ja tens això:
  static void showExitWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prem enrere un altre cop per sortir")),
    );
  }

  // 👉 AFEGEIX AIXÒ (és el que falta)
  static Future<bool?> showGpsDisabledDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS desactivat'),
        content: const Text('El GPS està desactivat. Vols activar-lo ara?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obrir configuració'),
          ),
        ],
      ),
    );
  }

  // Ja tens això també:
  static Future<bool?> showExportDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exportar GPX"),
        content: const Text("Vols exportar el track ara?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel·lar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Exportar"),
          ),
        ],
      ),
    );
  }
}
