import 'package:flutter/material.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'app_action_button.dart';

class IdleButtons extends StatelessWidget {
  final VoidCallback onStart;
  final Widget importButton;

  const IdleButtons({
    super.key,
    required this.onStart,
    required this.importButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppActionButton(
          flex: 2,
          color: AppColors.tertiary,
          onPressed: onStart,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 28),
              SizedBox(width: 8),
              Text(
                "INICIA RUTA",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: importButton),
      ],
    );
  }
}
