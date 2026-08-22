// lib/screens/main_map/widgets/map_selection_reticle.dart
import 'package:flutter/material.dart';

/// Creu que travessa tota la pantalla (vertical i horitzontal) amb un quadrat
/// buit de 5x5 px al punt d'intersecció central. S'usa com a mira real sobre el mapa.
class MapFullScreenReticle extends StatelessWidget {
  final Color color;

  const MapFullScreenReticle({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _FullScreenReticlePainter(color: color),
        );
      },
    );
  }
}

class _FullScreenReticlePainter extends CustomPainter {
  final Color color;
  static const double squareSize = 5.0;

  _FullScreenReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), linePaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    final squarePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: squareSize,
        height: squareSize,
      ),
      squarePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FullScreenReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MapSelectionReticle extends StatelessWidget {
  final Color color;

  const MapSelectionReticle({
    super.key,
    required this.color, // Rebent el color dinàmic (verd o vermell) des del pare
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 RETICLE DUPLEX D'ALTA VISIBILITAT:
    // Utilitzem una mida fixa quadrada on es dibuixarà la circumferència exterior i la creu.
    return CustomPaint(
      size: const Size(44, 44),
      painter: _ReticlePainter(color: color),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final Color color;

  _ReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2;

    // 🎯 1. CONFIGURACIÓ DE PINZELLS (Anell, línies gruixudes i línies fines)
    final ringPaint = Paint()
      ..color = color
      ..strokeWidth =
          2.0 // Gruix de la circumferència exterior
      ..style = PaintingStyle.stroke;

    final thickPaint = Paint()
      ..color = color
      ..strokeWidth =
          3.5 // Línies exteriors gruixudes de la retícula
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final thinPaint = Paint()
      ..color = color
      ..strokeWidth =
          1.0 // Línies interiors fines de màxima precisió
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // 🎯 2. DIBUIX DE L'ANELL EXTERIOR
    canvas.drawCircle(
      Offset(cx, cy),
      radius - (ringPaint.strokeWidth / 2),
      ringPaint,
    );

    // 🎯 3. DEFINICIÓ DE LES DISTÀNCIES (Proporcions basades en la imatge)
    // - El traç gruixut comença a la vora del cercle i s'apropa al centre.
    // - Després es tanca en punta/triangle cap a la línia fina.
    // - Les línies fines s'apropen al centre deixant un petit espai buit a la intersecció.

    final double thickStart =
        radius - ringPaint.strokeWidth; // Toca la vora interna del cercle
    final double thickEnd = radius * 0.45; // On acaba el bloc gruixut
    final double thinStart =
        radius * 0.35; // On comença la línia fina (després de la punta)
    const double centerGap =
        2.0; // El petit buit lliure al centre exacte (sense punt)

    // 🎯 4. DIBUIX DE LES LÍNIES GROIXUDES (Amb la punta bisellada/estrenyida cap al centre)
    final thickPath = Path()
      // Superior
      ..moveTo(cx, cy - thickStart)
      ..lineTo(cx, cy - thickEnd)
      // Inferior
      ..moveTo(cx, cy + thickStart)
      ..lineTo(cx, cy + thickEnd)
      // Esquerra
      ..moveTo(cx - thickStart, cy)
      ..lineTo(cx - thickEnd, cy)
      // Dreta
      ..moveTo(cx + thickStart, cy)
      ..lineTo(cx + thickEnd, cy);
    canvas.drawPath(thickPath, thickPaint);

    // Dibuix de les puntes de transició (Triangles de transició de gruixut a fi)
    final transitionsPath = Path()
      // Superior
      ..moveTo(cx - 1.75, cy - thickEnd)
      ..lineTo(cx + 1.75, cy - thickEnd)
      ..lineTo(cx, cy - thinStart)
      ..close()
      // Inferior
      ..moveTo(cx - 1.75, cy + thickEnd)
      ..lineTo(cx + 1.75, cy + thickEnd)
      ..lineTo(cx, cy + thinStart)
      ..close()
      // Esquerra
      ..moveTo(cx - thickEnd, cy - 1.75)
      ..lineTo(cx - thickEnd, cy + 1.75)
      ..lineTo(cx - thinStart, cy)
      ..close()
      // Dreta
      ..moveTo(cx + thickEnd, cy - 1.75)
      ..lineTo(cx + thickEnd, cy + 1.75)
      ..lineTo(cx + thinStart, cy)
      ..close();

    final transitionPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(transitionsPath, transitionPaint);

    // 🎯 5. DIBUIX DE LES LÍNIES FINES DE PRECISIÓ
    final thinPath = Path()
      // Superior interna
      ..moveTo(cx, cy - thinStart)
      ..lineTo(cx, cy - centerGap)
      // Inferior interna
      ..moveTo(cx, cy + thinStart)
      ..lineTo(cx, cy + centerGap)
      // Esquerra interna
      ..moveTo(cx - thinStart, cy)
      ..lineTo(cx - centerGap, cy)
      // Dreta interna
      ..moveTo(cx + thinStart, cy)
      ..lineTo(cx + centerGap, cy);
    canvas.drawPath(thinPath, thinPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
