import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;

  const IdleButtons({super.key, required this.onStart});

  static const double buttonHeight = 48;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SizedBox(
      height: buttonHeight,
      width: double.infinity,
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
    );
  }
}
