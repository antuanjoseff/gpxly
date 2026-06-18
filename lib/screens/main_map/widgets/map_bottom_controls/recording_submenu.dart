import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class RecordingSubMenu extends StatelessWidget {
  final RecordingState state;
  final void Function(String action) onAction;
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
    final Color fonsDialog = AppColors.skyBlueDark.withAlpha(225);

    // 1. CAS ATURAT (IDLE): Un sol botó compacte centrat
    if (state == RecordingState.idle) {
      return Container(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: Text(
            t.recordStart.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () {
            onClose();
            onAction('start');
          },
        ),
      );
    }

    // 2. CAS GRAVANT O EN PAUSA: Els dos botons units simètrics nets
    final bool isRecording = state == RecordingState.recording;

    return Container(
      // Limitem l'amplada màxima de la pastilla central flotant perquè quedi estètica i no ocupi tota la pantalla
      constraints: const BoxConstraints(maxWidth: 340),

      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize
            .min, // 🎯 FORCEM al Row a ocupar el mínim espai necessari
        children: [
          // ◀️ BOTÓ ESQUERRA: Pausa o Reprendre (Mida flexible controlada pel Row)
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecording
                    ? Colors.amber.shade700
                    : Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    topRight: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                ),
              ),
              icon: Icon(
                isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                (isRecording ? t.recordPause : t.recordResume).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                onClose();
                onAction(isRecording ? 'pause' : 'resume');
              },
            ),
          ),

          // ▶️ BOTÓ DRETA: Aturar (Stop)
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redAlert,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.zero,
                    bottomLeft: Radius.zero,
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              icon: const Icon(Icons.stop_rounded, size: 22),
              label: Text(
                t.recordStop.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                onClose();
                onAction('stop');
              },
            ),
          ),
        ],
      ),
    );
  }
}
