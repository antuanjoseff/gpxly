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
        // CORRECCIÓN: Accedemos e incrementamos directamente los índices del array sin reasignar la lista
        counts[netName]![1] =
            counts[netName]![1] + 1; // Incrementamos visibles (Índice 1)

        if (map['usedInFix'] as bool) {
          counts[netName]![0] =
              counts[netName]![0] + 1; // Incrementamos activos (Índice 0)
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: networks.map((net) {
          // Extraemos los valores de los índices correspondientes
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
    );
  }
}
