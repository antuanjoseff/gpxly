import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/elevation_progress_notifier.dart';
import '../theme/app_colors.dart';

class AppMessages {
  // --- Estil de botó reutilitzable per a coherència ---
  static ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ), // 👈 Padding lateral i vertical
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // 1. Avís de sortida
  static void showExitWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prem enrere un altre cop per sortir")),
    );
  }

  // 2. Diàleg de GPS desactivat
  static Future<bool?> showGpsDisabledDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS desactivat'),
        content: const Text('El GPS està desactivat. Vols activar-lo ara?'),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // 👈 Espaiat del grup de botons
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL·LAR'),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIGURACIÓ'),
          ),
        ],
      ),
    );
  }

  // 3. Diàleg de Recuperació de Ruta
  static Future<bool?> showRecoverTrackDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.history, color: AppColors.mustardYellow),
            SizedBox(width: 10),
            Text(
              "Ruta pendent",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "S'ha detectat una gravació que no es va tancar correctament. Vols continuar-la o començar-ne una de nova?",
          style: TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ), // 👈 Padding inferior per separar de la vora
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "DESCARTAR",
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8), // Separació extra entre botons
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("RECUPERAR"),
          ),
        ],
      ),
    );
  }

  // 4. Diàleg d'exportació
  static Future<bool?> showExportDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exportar GPX"),
        content: const Text("Vols exportar el track ara?"),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL·LAR"),
          ),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("EXPORTAR"),
          ),
        ],
      ),
    );
  }

  // 5. Diàleg de Progrés d'Elevació
  static void showElevationProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final progressState = ref.watch(elevationProgressProvider);
          final hasError = progressState.error != null;

          return AlertDialog(
            backgroundColor: AppColors.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              hasError ? "Error" : "Corregint altituds",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasError) ...[
                  ClipRRect(
                    // 👈 Arrodonim la barra de progrés
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressState.progress,
                      backgroundColor: Colors.white10,
                      color: AppColors.skyBlue,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${(progressState.progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: AppColors.mustardYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.all(16),
            actions: [
              if (hasError)
                ElevatedButton(
                  // 👈 Canviat a ElevatedButton per consistència quan hi ha error
                  style: _buttonStyle(AppColors.skyBlue),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text("TANCAR"),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Mètodes de missatgeria ràpida (SnackBars) ---
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 6. Diàleg de confirmació d'importació GPX
  static Future<bool?> showImportGpxConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: AppColors.mustardYellow),
            SizedBox(width: 10),
            Text(
              "Importar GPX",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Ja tens una ruta activa o dades carregades. Vols substituir-les pel fitxer GPX?",
          style: TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "CANCEL·LAR",
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("IMPORTAR"),
          ),
        ],
      ),
    );
  }

  // 7. Diàleg per entrar en Mode Visualització
  static Future<bool?> showViewModeDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.visibility_outlined, color: AppColors.mustardYellow),
            SizedBox(width: 10),
            Text(
              "Mode visualització",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Vols entrar en mode visualització? No s'afegiran punts nous i la gravació quedarà desactivada.",
          style: TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "NO",
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: _buttonStyle(AppColors.skyBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ACTIVAR"),
          ),
        ],
      ),
    );
  }
}
