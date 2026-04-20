import 'package:flutter/material.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/track_base_button.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onImportTrack;
  final VoidCallback onFollowTrack;
  final bool hasImportedTrack;
  final bool isFollowingTrack;

  const IdleButtons({
    super.key,
    required this.onStart,
    required this.onImportTrack,
    required this.onFollowTrack,
    required this.hasImportedTrack,
    required this.isFollowingTrack,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        // 🔴 BOTÓ INICIAR GRAVACIÓ — NOMÉS ICONA, COLOR VERMELL
        Expanded(
          child: TrackBaseButton(
            color: Colors.red, // ← vermell gravació
            onPressed: onStart,
            icon: Icons.fiber_manual_record, // ← icona de gravació
            text: null, // ← sense text
          ),
        ),

        const SizedBox(width: 12),

        // ⬆️ BOTÓ IMPORTAR TRACK — ICONA UPLOAD
        Expanded(
          child: TrackBaseButton(
            color: AppColors.tertiary,
            onPressed: onImportTrack,
            icon: Icons.file_upload_outlined, // ← icona upload
            text: t.importedTrack, // ← mateix text que abans
          ),
        ),

        // 🧭 BOTÓ SEGUIR RUTA — NOMÉS SI HI HA TRACK IMPORTAT
        if (hasImportedTrack) ...[
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedScale(
              scale: isFollowingTrack ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: TrackBaseButton(
                color: AppColors.tertiary, // fons del botó NO canvia
                onPressed: onFollowTrack,
                icon: Icons.navigation,
                iconColor: isFollowingTrack
                    ? AppColors
                          .secondary // groc mostassa → destaca molt
                    : Colors.white, // icona normal
                text: null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
