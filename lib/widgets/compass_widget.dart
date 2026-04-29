import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_speed_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'dart:math' as math;

class CompassScalePanel extends ConsumerWidget {
  const CompassScalePanel({super.key});

  String _formatMeters(double m) {
    if (m >= 1000) {
      final km = (m / 1000).round(); // sense decimals
      return "$km km";
    }
    return "${m.round()} m"; // també sense decimals
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = ref.watch(compassHeadingProvider);
    final zoom = ref.watch(mapZoomProvider);
    final latitude = ref.watch(mapCenterLatProvider);

    // Càlcul escala
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

    const maxWidthPx =
        40.0; // Reduït una mica per anar a joc amb els 52px totals
    final niceScales = <double>[
      10,
      20,
      50,
      100,
      200,
      500,
      1000,
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
      500000,
      1000000,
    ];

    double chosenMeters = niceScales.first;
    double chosenWidthPx = chosenMeters / metersPerPixel;

    for (final m in niceScales) {
      final w = m / metersPerPixel;
      if (w <= maxWidthPx) {
        chosenMeters = m;
        chosenWidthPx = w;
      } else {
        break;
      }
    }

    return Container(
      width: 52, // 🎯 Amplada fixa per a tot el panell
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🧭 BRÚIXOLA PETITA (32px)
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                // Lletres més petites (size 7) i més properes al centre
                Positioned(top: 1, child: _label("N")),
                Positioned(bottom: 1, child: _label("S")),
                Positioned(left: 1, child: _label("W")),
                Positioned(right: 1, child: _label("E")),

                AnimatedRotation(
                  turns: heading / 360,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: CustomPaint(
                    size: const Size(10, 10), // Fletxa més petita
                    painter: _CompassArrowPainter(),
                  ),
                ),
                Container(
                  width: 2,
                  height: 2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 📏 ESCALA
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMeters(chosenMeters),
                style: const TextStyle(
                  fontSize: 9, // Text un pèl més petit
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: chosenWidthPx.clamp(4, maxWidthPx),
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
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
        fontSize: 7, // Reduït de 8 a 7
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _CompassArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h * 0.8) // Li dono un toc més estilitzat a la base
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
