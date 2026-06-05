// lib/widgets/range_info_panel.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/utils/distance_utils.dart';

class RangeInfoPanel extends ConsumerWidget {
  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final bool isChartCollapsed;

  const RangeInfoPanel({
    super.key,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.isChartCollapsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ FILTRE 1: Si la nansa està col·lapsada o no hi ha tram, el panell s'esvaeix de l'arbre
    if (isChartCollapsed ||
        selectedIndexStart == null ||
        selectedIndexEnd == null) {
      return const SizedBox.shrink();
    }

    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);

    final realAlts = real.altitudes;
    final realDists = real.distances;
    final importedAlts = imported?.altitudes ?? <double>[];

    // 🛡️ FILTRE 2: Si no hi ha cap mena de track actiu, sortim invisibles
    if (realAlts.isEmpty && (imported == null || imported.altitudes.isEmpty)) {
      return const SizedBox.shrink();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 🧮 LÒGICA DE CÀLCUL DE COMPACTACIÓ DE TRAM DE SENDA
    // ─────────────────────────────────────────────────────────────────────────
    final List<double> futureDists = imported != null
        ? calculateDistances(imported.coordinates)
        : [];
    final globalDists = <double>[...realDists, ...futureDists];
    final globalAlts = <double>[...realAlts, ...importedAlts];

    double rangeDistance = 0;
    double rangeAscent = 0;
    double rangeDescent = 0;

    final start = selectedIndexStart!;
    final end = selectedIndexEnd!;

    if (start < globalDists.length && end < globalDists.length) {
      rangeDistance = (globalDists[end] - globalDists[start]).abs();

      final int startIdx = start < end ? start : end;
      final int endIdx = start < end ? end : start;

      for (int i = startIdx + 1; i <= endIdx; i++) {
        if (i >= globalAlts.length) break;
        final diff = globalAlts[i] - globalAlts[i - 1];
        if (diff > 0) rangeAscent += diff;
        if (diff < 0) rangeDescent += diff.abs();
      }
    }

    final t = AppLocalizations.of(context)!;
    // lib/widgets/range_info_panel.dart (BLOC 2 DE 2)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.75,
        ), // Fondo fosc translúcid original de Senda
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DADES DEL TRAM",
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Icona universal recta de distància compacta
          _buildTelemetryLine(
            icon: Icons.straighten,
            label: "${t.statRangeDistance}:",
            value: "${(rangeDistance / 1000).toStringAsFixed(2)} km",
            color: Colors.white,
          ),

          const SizedBox(height: 4),

          // Icona universal d'ascens acumulat de cota de Senda
          _buildTelemetryLine(
            icon: Icons.arrow_upward,
            label: "Ascens:",
            value: "+${rangeAscent.toStringAsFixed(0)} m",
            color: Colors.greenAccent,
            isBold: true,
          ),

          const SizedBox(height: 4),

          // Icona universal de descens acumulat de cota de Senda
          _buildTelemetryLine(
            icon: Icons.arrow_downward,
            label: "Descens:",
            value: "-${rangeDescent.toStringAsFixed(0)} m",
            color: Colors.redAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.8)),
        const SizedBox(width: 6),
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
