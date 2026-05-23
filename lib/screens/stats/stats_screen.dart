import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/screens/stats/models/stat_chart_type.dart';
import 'package:senda/screens/stats/stats_detail_screen.dart';
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

    // Valors calculats per passar a la navegació
    final currentRealTime = _timeFor(real, liveDuration);
    final currentRealElev = "${real.maxElevation.toStringAsFixed(0)} m";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.trackStatsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(t, hasImported),

          const SizedBox(height: 8),

          // --- BLOC 1: RENDIMENT ---
          _StatGroupCard(
            title: t.statTime.toUpperCase(),
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.speed_rounded,
              label: "Rendiment",
              valueReal:
                  currentRealTime, // Passem el temps com a valor principal
              chartType: StatChartType.speed,
              real: real,
              imported: imported,
              valueImported: hasImported ? imported!.formattedDuration : null,
            ),
            rows: [
              _StatRow(
                label: t.statTime,
                valueReal: currentRealTime,
                valueImported: hasImported && imported!.hasTimeData
                    ? imported.formattedDuration
                    : null,
              ),
              _StatRow(
                label: t.statDistance,
                valueReal: real.coordinates.isNotEmpty
                    ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                    : "---",
                valueImported: hasImported
                    ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                    : null,
              ),
              _StatRow(
                label: t.statSpeed,
                valueReal: real.hasTimeData
                    ? "${real.averageSpeed.toStringAsFixed(1)} km/h"
                    : "---",
                valueImported: hasImported && imported!.hasTimeData
                    ? "${imported.averageSpeed.toStringAsFixed(1)} km/h"
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- BLOC 2: ALTIMETRIA ---
          _StatGroupCard(
            title: t.statMaxElevation.toUpperCase(),
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.terrain_rounded,
              label: "Altimetria",
              valueReal:
                  currentRealElev, // Passem l'altura màxima com a valor principal
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
              valueImported: hasImported
                  ? "${imported!.maxElevation.toStringAsFixed(0)} m"
                  : null,
            ),
            rows: [
              _StatRow(
                label: t.statMaxElevation,
                valueReal: currentRealElev,
                valueImported: hasImported
                    ? "${imported!.maxElevation.toStringAsFixed(0)} m"
                    : null,
              ),
              _StatRow(
                label: t.statMinElevation,
                valueReal: "${real.minElevation.toStringAsFixed(0)} m",
                valueImported: hasImported
                    ? "${imported!.minElevation.toStringAsFixed(0)} m"
                    : null,
              ),
              _StatRow(
                label: t.statAscent,
                valueReal: "${real.ascent.toStringAsFixed(0)} m",
                valueImported: hasImported
                    ? "${imported!.ascent.toStringAsFixed(0)} m"
                    : null,
              ),
              _StatRow(
                label: t.statDescent,
                valueReal: "${real.descent.toStringAsFixed(0)} m",
                valueImported: hasImported
                    ? "${imported!.descent.toStringAsFixed(0)} m"
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  // (Manté els mètodes privats _buildHeader, _timeFor, _navigateToDetail igual)

  // --- CAPÇALERA ---
  // --- CAPÇALERA ALINEADA ---
  Widget _buildHeader(AppLocalizations t, bool hasImported) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Mateix espai que l'etiqueta de la fila (flex: 3)
          const Expanded(flex: 3, child: SizedBox.shrink()),

          // Columna Track Real (flex: 2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.redAlert.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                t.recordingTrack.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.redAlert,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8), // Petit espai entre columnes
          // Columna Track Importat (flex: 2)
          if (hasImported)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.trackGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.importedTrack.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.trackGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          else
            const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  // --- NEW SCREEN ---
  // --- NAVEGACIÓ AMB EFECTE SWAP ---
  void _navigateToDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String valueReal,
    required StatChartType chartType,
    Track? real,
    Track? imported,
    String? valueImported,
  }) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        // <--- Això activa el gest de swipe lateral
        builder: (context) => StatDetailScreen(
          icon: icon,
          label: label,
          valueReal: valueReal,
          valueImported: valueImported,
          chartType: chartType,
          realTrack: real,
          importedTrack: imported,
        ),
      ),
    );
  }

  // --- TEMPS ---
  String _timeFor(Track t, Duration live) {
    switch (t.recordingState) {
      case RecordingState.recording:
        return _formatDuration(live);
      case RecordingState.paused:
        return t.formattedDuration;
      default:
        return "---";
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }
}

class _StatGroupCard extends StatelessWidget {
  final String title;
  final List<_StatRow> rows;
  final VoidCallback onTap;

  const _StatGroupCard({
    required this.title,
    required this.rows,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Petit indicador que es pot clicar (opcional)
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.show_chart, size: 16, color: Colors.grey),
              ),
            ),
            ...rows,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String valueReal;
  final String? valueImported;

  const _StatRow({
    required this.label,
    required this.valueReal,
    this.valueImported,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Etiqueta (flex: 3)
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          // Valor Real (flex: 2) - Color RedAlert per sincronitzar amb header
          Expanded(
            flex: 2,
            child: Text(
              valueReal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.redAlert, // Sincronitzat amb el header
                fontSize: 15,
              ),
            ),
          ),

          // Valor Importat (flex: 2)
          if (valueImported != null)
            Expanded(
              flex: 2,
              child: Text(
                valueImported!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.trackGreen,
                  fontSize: 15,
                ),
              ),
            )
          else
            const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
