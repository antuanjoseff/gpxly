import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/widgets/track_base_button.dart';

class RecordingButtons extends ConsumerWidget {
  final VoidCallback onPause;
  final VoidCallback onImportTrack;
  final VoidCallback onFollowTrack;

  const RecordingButtons({
    super.key,
    required this.onPause,
    required this.onImportTrack,
    required this.onFollowTrack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final followState = ref.watch(trackFollowNotifierProvider);
    final imported = ref.watch(importedTrackProvider);
    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    return Row(
      children: [
        // PAUSA
        Expanded(
          child: TrackBaseButton(
            color: AppColors.secondary,
            onPressed: onPause,
            icon: Icons.pause,
            text: t.pause,
          ),
        ),

        const SizedBox(width: 12),

        // SI NO HI HA TRACK IMPORTAT → MOSTRAR IMPORTAR
        if (!hasImported)
          Expanded(
            child: TrackBaseButton(
              color: AppColors.secondary,
              onPressed: onImportTrack,
              icon: Icons.route,
              text: "Track",
            ),
          ),

        // SI HI HA TRACK IMPORTAT → MOSTRAR SEGUIR / ATURA SEGUIMENT
        if (hasImported)
          Expanded(
            child: TrackBaseButton(
              color: followState.isFollowing
                  ? AppColors.tertiary
                  : AppColors.secondary,
              onPressed: onFollowTrack,
              icon: followState.isFollowing ? Icons.close : Icons.navigation,
              text: followState.isFollowing ? t.stopFollowing : t.follow,
            ),
          ),
      ],
    );
  }
}
