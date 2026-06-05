// lib/stats/satellites/screens/constellation_page.dart
import 'package:flutter/material.dart';

class ConstellationPage extends StatelessWidget {
  final List<dynamic> satellites;
  final Map<String, String> Function(int, int) parseFn;

  const ConstellationPage({
    super.key,
    required this.satellites,
    required this.parseFn,
  });

  @override
  Widget build(BuildContext context) {
    final networks = ['GPS', 'GALILEO', 'GLONASS', 'BEIDOU'];

    // Lista fija de 2 enteros: [0] = Activos, [1] = Visibles
    final Map<String, List<int>> counts = {
      'GPS': List<int>.filled(2, 0),
      'GALILEO': List<int>.filled(2, 0),
      'GLONASS': List<int>.filled(2, 0),
      'BEIDOU': List<int>.filled(2, 0),
    };

    for (var sat in satellites) {
      final map = Map<String, dynamic>.from(sat);
      final parsed = parseFn(map['constellation'] as int, map['svid'] as int);
      final netName = parsed['name']!;

      if (counts.containsKey(netName)) {
        // Incrementamos visibles (Índice 1)
        counts[netName]![1] = counts[netName]![1] + 1;

        if (map['usedInFix'] as bool) {
          // Incrementamos activos (Índice 0)
          counts[netName]![0] = counts[netName]![0] + 1;
        }
      }
    }

    // 🗺️ Formas geométricas que coinciden con los símbolos de tu visor/radar
    final Map<String, IconData> networkIcons = {
      'GPS': Icons.circle, // Círculo
      'GALILEO': Icons.square, // Cuadrado
      'GLONASS': Icons.change_history, // Triángulo
      'BEIDOU': Icons.hexagon, // Hexágono
    };

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          // 🗺️ Leyenda de Formas Geométricas (Esquina superior derecha)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: networks.map((net) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          networkIcons[net],
                          size: 11,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          net == 'GALILEO'
                              ? 'Galileo'
                              : net == 'GLONASS'
                              ? 'Glonass'
                              : net == 'BEIDOU'
                              ? 'BeiDou'
                              : 'GPS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 📊 Gráficos de barras de las constelaciones
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: networks.map((net) {
              final used = counts[net]![0]; // Posición 0: Activos
              final view = counts[net]![1]; // Posición 1: Visibles
              final double percent = view > 0 ? used / view : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        net == 'GALILEO'
                            ? 'Galileo'
                            : net == 'GLONASS'
                            ? 'Glonass'
                            : net == 'BEIDOU'
                            ? 'BeiDou'
                            : 'GPS',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$used / $view',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
