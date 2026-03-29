import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pedometer_service.dart';
import '../models/user_profile.dart';
import '../utils/calculations.dart';
import 'profile_screen.dart';
import 'track_screen.dart';
import '../services/battery_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int steps = ref.watch(stepCountProvider);
    UserProfile profile = UserProfile(sexo: 'M', altura: 170, peso: 70);
    double calories = calculateCalories(steps, profile);

    return Scaffold(
      appBar: AppBar(title: const Text("GPXly")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pasos: $steps", style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 20),
            Text(
              "Calorías: ${calories.toStringAsFixed(1)} kcal",
              style: const TextStyle(fontSize: 25),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: requestBatteryExclusion,
              child: const Text("Optimización de batería"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const Text("Perfil"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackScreen()),
                );
              },
              child: const Text("Iniciar Track"),
            ),
          ],
        ),
      ),
    );
  }
}
