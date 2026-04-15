import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class IdleButtons extends ConsumerWidget {
  final VoidCallback onStart;
  final Widget importButton;

  const IdleButtons({
    super.key,
    required this.onStart,
    required this.importButton,
  });

  static const double buttonHeight = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imported = ref.watch(importedTrackProvider);
    final hasImported = imported!.coordinates.isNotEmpty;

    return Flex(
      direction: Axis.horizontal,
      children: [
        if (hasImported) ...[
          Expanded(
            flex: 2, // 2/5
            child: SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  ref
                      .read(trackFollowNotifierProvider.notifier)
                      .startFollowingWithRecording(context);
                },
                child: const Text("Seguir"),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        Expanded(
          flex: 3, // 3/5
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                "Inicia gravació",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
