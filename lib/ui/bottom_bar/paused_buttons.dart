import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'app_action_button.dart';

class PausedButtons extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onStop;

  const PausedButtons({
    super.key,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        AppActionButton(
          flex: 2,
          color: AppColors.primary.withAlpha(180),
          onPressed: onResume,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow),
              const SizedBox(width: 8),
              Text(
                t.resume, // ← traduït
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppActionButton(
          flex: 1,
          color: Colors.red,
          onPressed: onStop,
          child: const Icon(Icons.stop, size: 26),
        ),
      ],
    );
  }
}
