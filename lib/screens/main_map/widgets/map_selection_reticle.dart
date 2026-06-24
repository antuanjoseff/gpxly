// lib/screens/main_map/widgets/map_selection_reticle.dart
import 'package:flutter/material.dart';

class MapSelectionReticle extends StatelessWidget {
  final Color color;

  const MapSelectionReticle({
    super.key,
    required this.color, // Rebent el color dinàmic (verd o vermell) des del pare
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 DISSENY DE RETICLE CREUAT D'ALT RENDIMENT VISUAL:
    // Creem un punt de mira gros de 44x44px combinant un punt central i una creu de vector.
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

    // 🎯 1. CONFIGURACIÓ DEL PINZELL DE LA GPU
    final paint = Paint()
      ..color = color
      ..strokeWidth =
          3.5 // 🚀 MÉS GROIXUT: Pugem el traç de 2px a 3.5px per a una visibilitat brutal
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 🎯 2. DIBUIX DE LES LÍNIES DE LA CREU (Deixem un buit central de 6px net)
    final path = Path()
      // Línia Superior
      ..moveTo(cx, cy - 22)
      ..lineTo(cx, cy - 6)
      // Línia Inferior
      ..moveTo(cx, cy + 6)
      ..lineTo(cx, cy + 22)
      // Línia Esquerra
      ..moveTo(cx - 22, cy)
      ..lineTo(cx - 6, cy)
      // Línia Dreta
      ..moveTo(cx + 6, cy)
      ..lineTo(cx + 22, cy);

    canvas.drawPath(path, paint);

    // 🎯 3. PUNTA CENTRAL DE PRECISIÓ ABSOLUTA
    final centerDotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dibuixem un cercle massís de 3px de ràdi al centre exacte
    canvas.drawCircle(Offset(cx, cy), 3.0, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    // Es torna a pintar només si canviem del punt verd al vermell
    return oldDelegate.color != color;
  }
}
