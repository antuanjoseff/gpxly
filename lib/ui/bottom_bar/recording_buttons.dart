import 'package:flutter/material.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'app_action_button.dart';

class RecordingButtons extends StatelessWidget {
  final VoidCallback onPause;

  const RecordingButtons({super.key, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppActionButton(
          color: AppColors.secondary.withAlpha(180),
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
      ],
    );
  }
}
