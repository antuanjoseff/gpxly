import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'app_action_button.dart';

class RecordingButtons extends ConsumerWidget {
  final VoidCallback onPause;
  final Widget importButton; // 👈 AFEGIT

  const RecordingButtons({
    super.key,
    required this.onPause,
    required this.importButton, // 👈 AFEGIT
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
        AppActionButton(
          color: AppColors.secondary,
          onPressed: onPause,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pause),
              const SizedBox(width: 8),
              Text(
                t.pause,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // SI NO HI HA TRACK IMPORTAT → MOSTRAR IMPORTAR
        if (!hasImported)
          Expanded(
            child: importButton, // 👈 AFEGIT
          ),

        // SI HI HA TRACK IMPORTAT → MOSTRAR SEGUIR / ATURA SEGUIMENT
        if (hasImported)
          AppActionButton(
            color: followState.isFollowing
                ? AppColors.tertiary
                : AppColors.secondary,
            onPressed: () {
              ref
                  .read(trackFollowNotifierProvider.notifier)
                  .toggleFollowing(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(followState.isFollowing ? Icons.close : Icons.navigation),
                const SizedBox(width: 8),
                Text(
                  followState.isFollowing ? t.stopFollowing : t.follow,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
