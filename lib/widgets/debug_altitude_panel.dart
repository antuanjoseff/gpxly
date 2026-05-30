// lib/widgets/debug_altitude_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/core/altitude/altitude_processor.dart';

class DebugAltitudePanel extends ConsumerWidget {
  const DebugAltitudePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado completo del procesador de fusión en tiempo real
    final altState = ref.watch(altitudeProcessorProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(
          180,
        ), // Fondo oscuro translúcido para ver el mapa por detrás
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TELEMETRIA ALTITUD",
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          _buildTelemetryLine(
            label: "GPS Crut:",
            value: altState.gps,
            color: Colors.white70,
          ),
          _buildTelemetryLine(
            label: "DEM Mapa:",
            value: altState.dem,
            color: Colors.cyanAccent,
          ),
          _buildTelemetryLine(
            label: "BARO Cota:",
            value: altState.baro,
            color: Colors.orangeAccent,
          ),
          const Divider(color: Colors.white10, height: 10),
          _buildTelemetryLine(
            label: "FUSED Final:",
            value: altState.fused,
            color: Colors.greenAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryLine({
    required String label,
    required double? value,
    required Color color,
    bool isBold = false,
  }) {
    final String valStr = value != null
        ? "${value.toStringAsFixed(2)} m"
        : "---";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          Text(
            valStr,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
