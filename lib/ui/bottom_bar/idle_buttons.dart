import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;

  const IdleButtons({super.key, required this.onStart});

  static const double buttonHeight = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight,
      width: double.infinity, // ocupa tot l'espai disponible
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
    );
  }
}
