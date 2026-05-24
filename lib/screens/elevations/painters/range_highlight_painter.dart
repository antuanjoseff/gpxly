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
  final double
  minY; // ja no s’usa directament, però el mantenim per compatibilitat
  final double maxY; // ja no s’usa directament
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
    if (distances.isEmpty || altitudes.isEmpty) return;

    // ─────────────────────────────────────────────
    // 1) Calcular min/max reals del segment
    // ─────────────────────────────────────────────
    final double minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final double maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final double diff = maxAlt - minAlt;

    // ─────────────────────────────────────────────
    // 2) Exageració PRO progressiva
    // ─────────────────────────────────────────────
    double exaggeration = 1.0;

    if (diff < 30) {
      exaggeration = 1.8;
    } else if (diff < 60) {
      exaggeration = 1.4;
    } else if (diff < 100) {
      exaggeration = 1.2;
    }

    // ─────────────────────────────────────────────
    // 3) Rang efectiu mínim
    // ─────────────────────────────────────────────
    final double effectiveRange = diff < 50 ? 50 : diff;

    // ─────────────────────────────────────────────
    // 4) Aplicar exageració al rang vertical
    // ─────────────────────────────────────────────
    final double forcedMinY = minAlt - (effectiveRange * 0.3 * exaggeration);
    final double forcedMaxY =
        forcedMinY + (effectiveRange * 1.3 * exaggeration);

    final double yRange = forcedMaxY - forcedMinY;

    // ─────────────────────────────────────────────
    // 5) Dimensions del gràfic
    // ─────────────────────────────────────────────
    final double usableWidth = size.width - 48; // padding horitzontal
    final double chartHeight = size.height - 40; // bottomReserved
    final double maxDist = distances.last;

    // ─────────────────────────────────────────────
    // 6) Ordenar índexs
    // ─────────────────────────────────────────────
    final int start = startIndex < endIndex ? startIndex : endIndex;
    final int end = startIndex < endIndex ? endIndex : startIndex;

    final path = Path();

    // ─────────────────────────────────────────────
    // 7) Punt inicial a la base
    // ─────────────────────────────────────────────
    double firstX = (distances[start] / maxDist) * usableWidth + 24;
    path.moveTo(firstX, chartHeight);

    // ─────────────────────────────────────────────
    // 8) Resseguir el perfil exagerat
    // ─────────────────────────────────────────────
    for (int i = start; i <= end; i++) {
      double x = (distances[i] / maxDist) * usableWidth + 24;

      double relY = (altitudes[i] - forcedMinY) / yRange;
      double y = chartHeight - (relY * chartHeight);

      path.lineTo(x, y);
    }

    // ─────────────────────────────────────────────
    // 9) Tancar el polígon
    // ─────────────────────────────────────────────
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
