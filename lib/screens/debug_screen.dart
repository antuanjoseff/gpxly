import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class DebugSimulator extends ConsumerStatefulWidget {
  const DebugSimulator({super.key});

  @override
  ConsumerState<DebugSimulator> createState() => _DebugSimulatorState();
}

class _DebugSimulatorState extends ConsumerState<DebugSimulator> {
  LatLng base = const LatLng(41.9850, 2.8110); // Girona, sobre el track

  LatLng offset(double dx, double dy) =>
      LatLng(base.latitude + dx, base.longitude + dy);

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(trackFollowNotifierProvider.notifier);

    // 🔥 LISTENER AMB SNACKBARS I PRINTS
    ref.listen(trackFollowNotifierProvider, (prev, next) {
      print("--------------------------------------------------");
      print("STATE CHANGE:");
      print("mode: ${next.mode}");
      print("distanceToTrack: ${next.distanceToTrack}");
      print("showOffTrackSnackbar: ${next.showOffTrackSnackbar}");
      print("showBackOnTrackSnackbar: ${next.showBackOnTrackSnackbar}");
      print("showReverseTrackDialog: ${next.showReverseTrackDialog}");
      print("showEndOfTrackSnackbar: ${next.showEndOfTrackSnackbar}");
      print("--------------------------------------------------");

      // OFFTRACK
      if (next.showOffTrackSnackbar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🚨 OFFTRACK")));
        ref.read(trackFollowNotifierProvider.notifier).clearOffTrackSnackbar();
      }

      // BACK ON TRACK
      if (next.showBackOnTrackSnackbar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ BACK ON TRACK")));
        ref
            .read(trackFollowNotifierProvider.notifier)
            .dismissBackOnTrackAlert();
      }

      // END OF TRACK
      if (next.showEndOfTrackSnackbar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🏁 END OF TRACK")));
        ref.read(trackFollowNotifierProvider.notifier).dismissEndOfTrackAlert();
      }

      // REVERSED
      if (next.showReverseTrackDialog) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("↩️ REVERSED DETECTED")));
        ref
            .read(trackFollowNotifierProvider.notifier)
            .dismissReverseTrackDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Debug Simulator")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔵 ACTIVAR DEBUG
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(trackFollowNotifierProvider.notifier);

              notifier.debugMode = true;
              print(">>> DEBUG MODE ACTIVAT");

              final imported = ref.read(importedTrackProvider);
              if (imported == null || imported.coordinates.isEmpty) {
                print(">>> ERROR: No hi ha track importat!");
                return;
              }

              print(">>> TRACK IMPORTAT: ${imported.coordinates.length} punts");

              // IMPORTANT: cridar la nova funció amb els paràmetres correctes
              await notifier.startFollowingWithoutRecording(
                context,
                ref,
                null, // No tenim mapController al DebugSimulator
              );

              print(">>> FOLLOW sense gravar activat");
            },
            child: const Text("🔵 Activar FOLLOW sense gravar"),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final imported = ref.read(importedTrackProvider);
              if (imported == null || imported.coordinates.isEmpty) {
                print(">>> ERROR: No hi ha track importat!");
                return;
              }

              final first = imported.coordinates.first;
              final pos = LatLng(first[1], first[0]);

              print(">>> ONTRACK: primer punt del track = $pos");
              notifier.updateUserPosition(pos);
            },
            child: const Text(
              "1️⃣ Posar-me EXACTAMENT al PRIMER punt del track",
            ),
          ),

          const SizedBox(height: 20),
          const Text("📍 Posicions bàsiques"),

          ElevatedButton(
            onPressed: () {
              print(">>> ONTRACK: base");
              notifier.updateUserPosition(base);
            },
            child: const Text("1️⃣ Posar-me EXACTAMENT sobre el track"),
          ),

          ElevatedButton(
            onPressed: () {
              final p = offset(0.00015, 0.00015); // ~20m
              print(">>> ONTRACK (20m): $p");
              notifier.updateUserPosition(p);
            },
            child: const Text("2️⃣ Posar-me a 20m"),
          ),

          const SizedBox(height: 20),
          const Text("🚨 OFFTRACK"),

          ElevatedButton(
            onPressed: () {
              final p = offset(0.0006, 0.0006); // ~80m
              print(">>> OFFTRACK (80m): $p");
              notifier.updateUserPosition(p);
            },
            child: const Text("3️⃣ Sortir-me 80m"),
          ),

          ElevatedButton(
            onPressed: () async {
              print(">>> TRENDING AWAY");
              for (int i = 1; i <= 6; i++) {
                final p = offset(0.0001 * i, 0.0001 * i);
                print("   → $p");
                notifier.updateUserPosition(p);
                await Future.delayed(const Duration(milliseconds: 500));
              }
            },
            child: const Text("4️⃣ trendingAway"),
          ),

          const SizedBox(height: 20),
          const Text("↩️ REVERSED"),

          ElevatedButton(
            onPressed: () async {
              print(">>> REVERSED TEST");
              notifier.updateUserPosition(offset(0.0001, 0));
              await Future.delayed(const Duration(milliseconds: 500));
              notifier.updateUserPosition(offset(0.0002, 0));
              await Future.delayed(const Duration(milliseconds: 500));
              notifier.updateUserPosition(offset(0.0001, 0)); // reversed
            },
            child: const Text("5️⃣ Simular reversed"),
          ),

          const SizedBox(height: 20),
          const Text("🏁 END OF TRACK"),

          ElevatedButton(
            onPressed: () async {
              print(">>> ENDTRACK TEST");

              final imported = ref.read(importedTrackProvider);
              if (imported == null || imported.coordinates.isEmpty) {
                print(">>> ERROR: No hi ha track importat!");
                return;
              }

              final last = imported.coordinates.last;
              final lastPos = LatLng(last[1], last[0]);

              notifier.updateUserPosition(lastPos);
            },
            child: const Text("6️⃣ Simular final de track"),
          ),
        ],
      ),
    );
  }
}
