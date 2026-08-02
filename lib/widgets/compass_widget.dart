// lib/screens/main_map/widgets/compass_scale_panel.dart (AMPLADA CORPORATIVA 56PX)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/notifiers/gps_bearing_notifier.dart';
import 'package:strack_rec/notifiers/gps_speed_notifier.dart';
import 'package:strack_rec/notifiers/map_bearing_provider.dart';
import 'package:strack_rec/theme/app_colors.dart';

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

    final zoom = ref.watch(mapZoomProvider);
    final latitude = ref.watch(mapCenterLatProvider);

    // Càlcul escala
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

    // 🚀 OPTIMITZACIÓ GEOMÈTRICA:
    // Pugem l'amplada màxima de la línia d'escala a 44px perquè s'adapti perfectament al nou fons de 56px
    const maxWidthPx = 44.0;
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
      width:
          56.0, // 🎯 ACCORD CORPORATIU: Clavem exactament l'amplada a 56px igual que els botons quadrats i de les tisores!
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(
          16,
        ), // Manté el mateix radi visual d'estil de la graella
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🧭 BRÚIXOLA REPROPORCIONADA (Pugem a 36px perquè llueixi simètrica amb els 56px de fons)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapCompass,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  // 🔥 CAPA 1: LES LLETRES GIREN AMB EL MAPA
                  AnimatedRotation(
                    turns: -mapBearing / 360,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 2,
                          left: 0,
                          right: 0,
                          child: Center(child: _label("N")),
                        ),
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Center(child: _label("S")),
                        ),
                        Positioned(
                          left: 2,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _label("W")),
                        ),
                        Positioned(
                          right: 2,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _label("E")),
                        ),
                      ],
                    ),
                  ),

                  // 🔥 CAPA 2: LA FLETXA VA INDEPENDENT
                  AnimatedRotation(
                    turns: deviceHeading / 360,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: CustomPaint(
                      size: const Size(
                        12,
                        14,
                      ), // Un pèl més gran perquè acompanyi el nou diàmetre de 36px
                      painter: _CompassArrowPainter(),
                    ),
                  ),

                  Container(
                    width: 2.5,
                    height: 2.5,
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
        fontSize:
            8, // Pugem un puntet per millorar la lectura amb el diàmetre de 36px
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
      ..lineTo(w / 2, h * 0.8)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
