import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/track_base_button.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onImportTrack;

  const IdleButtons({
    super.key,
    required this.onStart,
    required this.onImportTrack,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        // BOTÓ INICIAR GRAVACIÓ
        Expanded(
          child: TrackBaseButton(
            color: AppColors.tertiary,
            onPressed: onStart,
            icon: Icons.play_arrow_rounded,
            text: t.startRecording,
          ),
        ),

        const SizedBox(width: 12),

        // BOTÓ IMPORTAR TRACK
        Expanded(
          child: TrackBaseButton(
            color: AppColors.tertiary,
            onPressed: onImportTrack,
            icon: Icons.route,
            text: "Track",
          ),
        ),
      ],
    );
  }
}
