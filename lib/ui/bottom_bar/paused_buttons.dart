import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/track_base_button.dart';

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
        // BOTÓ REPREN (flex 2)
        Expanded(
          flex: 2,
          child: TrackBaseButton(
            color: AppColors.tertiary,
            onPressed: onResume,
            icon: Icons.play_arrow,
            text: t.resume,
          ),
        ),

        const SizedBox(width: 12),

        // BOTÓ ATURA (flex 1)
        Expanded(
          flex: 1,
          child: TrackBaseButton(
            color: Colors.red,
            onPressed: onStop,
            icon: Icons.stop,
          ),
        ),
      ],
    );
  }
}
