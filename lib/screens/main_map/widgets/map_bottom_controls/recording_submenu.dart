import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class RecordingSubMenu extends StatelessWidget {
  final RecordingState state;
  final void Function(String action)
  onAction; // 1. CAMBIAT: Ara accepta un paràmetre de tipus String
  final VoidCallback onClose;

  const RecordingSubMenu({
    super.key,
    required this.state,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          if (state == RecordingState.idle)
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                ),
                label: Text(
                  t.recordStart,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction('start'); // Envia l'acció start
                },
              ),
            ),

          if (state == RecordingState.recording) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.pause_rounded, color: Colors.amber),
                label: Text(
                  t.recordPause,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction('pause'); // Envia l'acció pause
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.stop_rounded, color: AppColors.redAlert),
                label: Text(
                  t.recordStop,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction('stop'); // Envia l'acció stop cap al diàleg final
                },
              ),
            ),
          ],

          if (state == RecordingState.paused) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                ),
                label: Text(
                  t.recordResume,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction('resume'); // Envia l'acció resume
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.stop_rounded, color: AppColors.redAlert),
                label: Text(
                  t.recordStop,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  onClose();
                  onAction('stop'); // Envia l'acció stop cap al diàleg final
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
