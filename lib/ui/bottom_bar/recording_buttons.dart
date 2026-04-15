import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'app_action_button.dart';

class RecordingButtons extends ConsumerWidget {
  final VoidCallback onPause;

  const RecordingButtons({super.key, required this.onPause});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followState = ref.watch(trackFollowNotifierProvider);
    final imported = ref.watch(importedTrackProvider);
    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    return Row(
      children: [
        // PAUSA
        AppActionButton(
          color: AppColors.secondary,
          onPressed: onPause,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pause),
              SizedBox(width: 8),
              Text("PAUSA", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // SEGUIR / ATURA SEGUIMENT (només si hi ha track importat)
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
                  followState.isFollowing ? "ATURA" : "SEGUIR",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
