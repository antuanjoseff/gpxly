import 'package:flutter/material.dart';
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
    return Row(
      children: [
        AppActionButton(
          flex: 2,
          color: AppColors.primary.withAlpha(180),
          onPressed: onResume,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow),
              SizedBox(width: 8),
              Text("REPRÈN", style: TextStyle(fontWeight: FontWeight.bold)),
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
