import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/theme/app_colors.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final liveDuration = ref.watch(timerProvider);

    final hasImported = imported != null && imported.coordinates.isNotEmpty;
    // ... dins del ListView ...
    bool isValidElev(double elevation) => elevation.abs() < 9000;

    // Estils de text per a les capçaleres (Més visibles)
    const headerStyleRec = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900, // Molt més gruixut
      color: AppColors.redAlert, // Color pur
      letterSpacing: 0.8,
    );

    const headerStyleImp = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: AppColors.trackGreen, // Color pur
      letterSpacing: 0.8,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.trackStatsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- CAPÇALERA DE COLUMNES (DINÀMICA) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(width: 54), // Espai equivalent a icona + padding
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.redAlert.withAlpha(
                        20,
                      ), // Fons molt subtil per emmarcar el text
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        t.recordingTrack.toUpperCase(),
                        style: headerStyleRec,
                      ),
                    ),
                  ),
                ),
                if (hasImported) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.trackGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          t.importedTrack.toUpperCase(),
                          style: headerStyleImp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // --- SECCIÓ TEMPS I DISTÀNCIA ---
          _buildStatTile(
            icon: Icons.timer_outlined,
            label: t.statTime,

            // Nova lògica per mostrar el temps segons l'estat
            value1: () {
              final state = real.recordingState;
              if (state == RecordingState.recording) {
                // Temps en viu mentre grava
                return _formatDuration(liveDuration);
              }

              if (state == RecordingState.paused) {
                // Temps acumulat fins al moment de pausar
                return real.formattedDuration;
              }

              // Estat stopped o sense dades
              return real.hasTimeData ? real.formattedDuration : "---";
            }(),

            value2: hasImported && imported.hasTimeData
                ? imported.formattedDuration
                : null,
          ),

          _buildStatTile(
            icon: Icons.straighten_rounded,
            label: t.statDistance,
            value1: real.coordinates.isNotEmpty
                ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                : "---",
            value2: hasImported
                ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                : null,
          ),

          _buildStatTile(
            icon: Icons.speed_rounded,
            label: t.statSpeed,
            value1: real.hasTimeData
                ? "${real.averageSpeed.toStringAsFixed(1)} km/h"
                : "---",
            value2: hasImported && imported!.hasTimeData
                ? "${imported.averageSpeed.toStringAsFixed(1)} km/h"
                : null,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 32, thickness: 1),
          ),

          // --- SECCIÓ ALTIMETRIA ---
          // Helper per validar si l'altitud és real

          // --- SECCIÓ ALTIMETRIA ---
          _buildStatTile(
            icon: Icons.terrain_rounded,
            label: t.statMaxElevation,
            value1: real.hasElevationData && isValidElev(real.maxElevation)
                ? "${real.maxElevation.toStringAsFixed(0)} m"
                : "---",
            value2:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.maxElevation)
                ? "${imported.maxElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.south_east_rounded,
            label: t.statMinElevation,
            value1: real.hasElevationData && isValidElev(real.minElevation)
                ? "${real.minElevation.toStringAsFixed(0)} m"
                : "---",
            value2:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.minElevation)
                ? "${imported.minElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.unfold_less_rounded,
            label: t.statAscent,
            value1: real.hasAscentDescent
                ? "${real.ascent.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && imported!.hasAscentDescent
                ? "${imported.ascent.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.unfold_more_rounded,
            label: t.statDescent,
            value1: real.hasAscentDescent
                ? "${real.descent.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && imported!.hasAscentDescent
                ? "${imported.descent.toStringAsFixed(0)} m"
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value1,
    String? value2,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // O AppColors.surface si és Dark Mode
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icona i Etiqueta
          SizedBox(
            width: 46,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Valor Track Real (Vermell)
          Expanded(
            child: _valueBox(value: value1, color: AppColors.redAlert),
          ),

          // Valor Track Importat (Verd)
          if (value2 != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _valueBox(value: value2, color: AppColors.trackGreen),
            ),
          ],
        ],
      ),
    );
  }

  Widget _valueBox({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // Fons molt suau
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: color, // Text amb el color original per llegibilitat
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}
