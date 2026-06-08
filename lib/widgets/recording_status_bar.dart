// lib/widgets/recording_status_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/location_notifier.dart';

class RecordingStatusBar extends ConsumerWidget {
  final RecordingState state;
  final Duration duration;

  const RecordingStatusBar({
    super.key,
    required this.state,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛰️ Llegim reactivament l'altitud corregida del teu provider [INDEX]
    final userPos = ref.watch(locationProvider);
    final double? altitude = userPos?.altitude;

    // Control del color de contrast per al text del cronòmetre si està pausat
    final Color timerColor = state == RecordingState.paused
        ? Colors.greenAccent
        : Colors.white;

    // Gestió dinàmica de la icona inicial de reproducció (Play / Pausa)
    Widget? stateIcon;
    if (state == RecordingState.recording) {
      stateIcon = const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 18, // 📈 Augmentat de 14 a 18 per a millor visibilitat
      );
    } else if (state == RecordingState.paused) {
      stateIcon = const Icon(
        Icons.pause_rounded,
        color: Colors.white,
        size: 18, // 📈 Augmentat de 14 a 18 per a millor visibilitat
      );
    }

    return FittedBox(
      fit: BoxFit
          .scaleDown, // 🚀 PROTECCIÓ: S'encongeix proporcionalment només si el mòbil és molt estret [INDEX]
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🚀 Icona inicial d'estat de gravació
          if (stateIcon != null) ...[
            stateIcon,
            const SizedBox(
              width: 6,
            ), // Un pèl més de marge per anar a joc amb el text gran
          ],

          // ⏱️ Secció del Cronòmetre (Text més gran)
          Text(
            duration.toString().split('.').first.padLeft(8, "0"),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize:
                  16, // 📈 AUGMENTAT: Passa de 13 a 16 gràcies a l'espai alliberat! [INDEX]
              color: timerColor,
              letterSpacing: 0.5, // Un pèl més separat per llegir-se millor
            ),
          ),

          // 📏 Separador vertical discret central integrat [INDEX]
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ), // Un pèl més de marge horitzontal
            height: 18, // Una mica més alt per acompanyar el text gran
            width: 1.5,
            color: Colors
                .white30, // Blanc translúcid suau integrat directament sobre l'AppBar
          ),

          // ⛰️ Secció de l'Altitud actual (Icona i text més grans) [INDEX]
          const Icon(
            Icons.filter_hdr_rounded,
            color: Colors.white,
            size:
                20, // 📈 Augmentat de 16 a 20 per a millor visibilitat [INDEX]
          ),
          const SizedBox(width: 6),
          Text(
            altitude != null ? "${altitude.toStringAsFixed(0)}m" : "---m",
            style: const TextStyle(
              color: Colors.white,
              fontSize:
                  16, // 📈 AUGMENTAT: Passa de 13 a 16 per anar perfectament simètric [INDEX]
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
