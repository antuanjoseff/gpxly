import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;
  final Widget importButton; // 👈 AFEGIT

  const IdleButtons({
    super.key,
    required this.onStart,
    required this.importButton, // 👈 AFEGIT
  });

  static const double buttonHeight = 48;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        // BOTÓ INICIAR GRAVACIÓ
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                t.startRecording,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // BOTÓ IMPORTAR TRACK GUIA
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: importButton, // 👈 JA EL TENIES, NOMÉS L’USEM
          ),
        ),
      ],
    );
  }
}
