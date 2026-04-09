import 'package:flutter/material.dart';

class RangeHighlightPainter extends CustomPainter {
  final double? startX;
  final double? endX;
  final Color color;
  final double bottomReserved; // Normalment 40, com al teu gràfic

  RangeHighlightPainter({
    required this.startX,
    required this.endX,
    required this.color,
    this.bottomReserved = 40,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startX == null || endX == null) return;

    // Definim l'àrea vertical (des de dalt fins on comencen els títols)
    final double top = 0;
    final double bottom = size.height - bottomReserved;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dibuixem el rectangle entre les dues X
    final rect = Rect.fromLTRB(startX!, top, endX!, bottom);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(RangeHighlightPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.color != color;
  }
}

class RangeAreaPainter extends CustomPainter {
  final int startIndex;
  final int endIndex;
  final List<double> distances;
  final List<double> altitudes;
  final double minY;
  final double maxY;
  final Color color;

  RangeAreaPainter({
    required this.startIndex,
    required this.endIndex,
    required this.distances,
    required this.altitudes,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty) return;

    final double usableWidth = size.width - 48; // Marges de 24+24
    final double chartHeight = size.height - 40; // Espai títols
    final double maxDist = distances.last;
    final double yRange = maxY - minY;

    // 1. Decidir on comença i on acaba (per si l'usuari els creua)
    final int start = startIndex < endIndex ? startIndex : endIndex;
    final int end = startIndex < endIndex ? endIndex : startIndex;

    final path = Path();

    // 2. Començar a la base de l'eix X (cantó esquerre)
    double firstX = (distances[start] / maxDist) * usableWidth + 24;
    path.moveTo(firstX, chartHeight);

    // 3. Pujar fins al primer punt de la muntanya i resseguir tota la carena
    for (int i = start; i <= end; i++) {
      double x = (distances[i] / maxDist) * usableWidth + 24;
      double relY = (altitudes[i] - minY) / yRange;
      double y = chartHeight - (relY * chartHeight);
      path.lineTo(x, y);
    }

    // 4. Baixar fins a la base (cantó dret) i tancar el polígon
    double lastX = (distances[end] / maxDist) * usableWidth + 24;
    path.lineTo(lastX, chartHeight);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RangeAreaPainter oldDelegate) => true;
}
