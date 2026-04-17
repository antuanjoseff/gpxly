import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_altitude_notifier.dart';
import 'package:gpxly/notifiers/gps_speed_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'dart:math' as math;

class CompassAltitudePanel extends ConsumerWidget {
  const CompassAltitudePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = ref.watch(compassHeadingProvider);
    final altitude = ref.watch(gpsAltitudeProvider);

    // Escala provisional (demà la vincularem al zoom real)
    final int scaleMeters = 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🧭 Brúixola PRO compacta
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // DISC
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // CARDINALITATS
                Positioned(top: 3, child: _label("N")),
                Positioned(bottom: 3, child: _label("S")),
                Positioned(left: 3, child: _label("W")),
                Positioned(right: 3, child: _label("E")),

                // AGULLA
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heading),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 3.1415926535 / 180,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // CENTRE
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ⛰️ Altitud compacta
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terrain, size: 12, color: AppColors.secondary),
              const SizedBox(width: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  "${altitude.toStringAsFixed(0)}m",
                  key: ValueKey(altitude),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 📏 Escala gràfica
          Column(
            children: [
              Container(width: 50, height: 2, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                "$scaleMeters m",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class CompassAltitudeScaleRow extends ConsumerWidget {
  const CompassAltitudeScaleRow({super.key});

  String _formatMeters(double m) {
    if (m >= 1000) return "${(m / 1000).toStringAsFixed(1)} km";
    return "${m.toInt()} m";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = ref.watch(compassHeadingProvider);
    final altitude = ref.watch(gpsAltitudeProvider);
    final zoom = ref.watch(mapZoomProvider);
    final latitude = ref.watch(mapCenterLatProvider);

    // Escala provisional (demà la vincularem al zoom real)
    // --- CÀLCUL ESCALA REAL ---
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

    const maxWidthPx = 50.0; // ample màxim de la línia
    final niceScales = <double>[
      20,
      50,
      100,
      200,
      500,
      1000,
      2000,
      5000,
      10000,
      100000,
      1000000,
      5000000,
    ];

    double chosenMeters = niceScales.first;
    double chosenWidthPx = chosenMeters / metersPerPixel;

    for (final m in niceScales) {
      final w = m / metersPerPixel;
      if (w <= maxWidthPx) {
        chosenMeters = m;
        chosenWidthPx = w;
      }
    }

    // 🔥 LÍMIT REAL D’AMPLADA
    chosenWidthPx = chosenWidthPx.clamp(0, maxWidthPx);

    for (final m in niceScales) {
      final w = m / metersPerPixel;
      if (w <= maxWidthPx) {
        chosenMeters = m;
        chosenWidthPx = w;
      }
    }
    // --- FI CÀLCUL ESCALA ---

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🧭 Brúixola PRO compacta
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // DISC
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // CARDINALITATS
                Positioned(top: 3, child: _label("N")),
                Positioned(bottom: 3, child: _label("S")),
                Positioned(left: 3, child: _label("W")),
                Positioned(right: 3, child: _label("E")),

                // AGULLA
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heading),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 3.1415926535 / 180,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // CENTRE
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // 📦 Bloc vertical: Altitud + Escala
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⛰️ Altitud
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.terrain,
                    size: 12,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      "${altitude.toStringAsFixed(0)}m",
                      key: ValueKey(altitude),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 📏 Escala real
              // 📏 Escala real (text a sobre i centrat)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatMeters(chosenMeters),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: chosenWidthPx,
                    height: 2,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
