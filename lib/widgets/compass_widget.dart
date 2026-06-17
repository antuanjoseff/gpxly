import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/gps_bearing_notifier.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';
import 'package:senda/notifiers/map_bearing_provider.dart';
import 'package:senda/theme/app_colors.dart';

class CompassScalePanel extends ConsumerWidget {
  final VoidCallback? onTapCompass;
  const CompassScalePanel({super.key, this.onTapCompass});

  String _formatMeters(double m) {
    if (m >= 1000) {
      final km = (m / 1000).round();
      return "$km km";
    }
    return "${m.round()} m";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceHeading = ref.watch(gpsBearingProvider);
    final mapBearing = ref.watch(mapBearingProvider);

    // Ja no ens cal la variable compassRotation aquí perquè ho dividim en dues animacions netes

    final zoom = ref.watch(mapZoomProvider);
    final latitude = ref.watch(mapCenterLatProvider);

    // Càlcul escala
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

    const maxWidthPx = 40.0;
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
      width: 52,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapCompass,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle blanc de fons (Estàtic, no cal que giri de fons)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  // 🔥 CAPA 1: NOMÉS LES LLETRES GIREN AMB EL MAPA
                  AnimatedRotation(
                    turns: -mapBearing / 360,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 1,
                          left: 0,
                          right: 0,
                          child: Center(child: _label("N")),
                        ),
                        Positioned(
                          bottom: 1,
                          left: 0,
                          right: 0,
                          child: Center(child: _label("S")),
                        ),
                        Positioned(
                          left: 1,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _label("W")),
                        ),
                        Positioned(
                          right: 1,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _label("E")),
                        ),
                      ],
                    ),
                  ),

                  // 🔥 CAPA 2: LA FLETXA VA INDEPENDENT (Apunta al Nord GPS real sense heretar el gir de les lletres)
                  AnimatedRotation(
                    turns: deviceHeading / 360,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: CustomPaint(
                      size: const Size(
                        10,
                        12,
                      ), // He donat 2px més d'alçada perquè llueixi més estilitzada
                      painter: _CompassArrowPainter(),
                    ),
                  ),

                  // Punt central decoratiu superior
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
          ),

          const SizedBox(height: 10),

          // 📏 ESCALA
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMeters(chosenMeters),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: chosenWidthPx.clamp(20, maxWidthPx),
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
        fontSize: 7,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
} // 👈 CORRECCIÓ: Tancament de la classe principal CompassScalePanel afegit de forma neta

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
      ..lineTo(w / 2, h * 0.8)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
