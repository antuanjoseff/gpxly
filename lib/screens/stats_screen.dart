import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_notifier.dart';

// ... els teus imports ...

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackProvider);

    // Comprovació de seguretat per a les elevacions inicials
    final hasData = track.coordinates.isNotEmpty;
    final maxElev = hasData
        ? "${track.maxElevation.toStringAsFixed(0)} m"
        : "---";
    final minElev = hasData
        ? "${track.minElevation.toStringAsFixed(0)} m"
        : "---";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dades de la ruta"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AFEGIM EL TEMPS
          _buildStatCard(
            "Temps total",
            track.formattedDuration,
            Icons.timer,
            Colors.orange,
          ),

          _buildStatCard(
            "Distància",
            "${(track.distance / 1000).toStringAsFixed(2)} km",
            Icons.straighten,
            Colors.blue,
          ),
          _buildStatCard(
            "Velocitat Mitjana",
            "${track.averageSpeed.toStringAsFixed(1)} km/h",
            Icons.speed,
            Colors.blue,
          ),
          const Divider(height: 30),
          _buildStatCard(
            "Elevació Màxima",
            maxElev,
            Icons.terrain,
            Colors.brown,
          ),
          _buildStatCard(
            "Elevació Mínima",
            minElev,
            Icons.south_east,
            Colors.brown,
          ),

          // COLORS PER ALS DESNIVELLS
          _buildStatCard(
            "Desnivell Positiu (+)",
            "${track.ascent.toStringAsFixed(0)} m",
            Icons.unfold_less,
            Colors.green,
          ),
          _buildStatCard(
            "Desnivell Negatiu (-)",
            "${track.descent.toStringAsFixed(0)} m",
            Icons.unfold_more,
            Colors.red,
          ),
        ],
      ),
    );
  }

  // Hem afegit un paràmetre 'color' per a la icona
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
