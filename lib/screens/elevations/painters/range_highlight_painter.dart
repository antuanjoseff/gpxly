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
  final int realPointsCount; // Longitud del track gravat (pastDists.length)
  final Color trackColor; // Color blau corporatiu de Senda

  RangeAreaPainter({
    required this.startIndex,
    required this.endIndex,
    required this.distances,
    required this.altitudes,
    required this.realPointsCount,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    // 1) Lògica d'escalat vertical automàtic i exageració (La teva fórmula de Senda)
    final double minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final double maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final double diff = maxAlt - minAlt;

    double exaggeration = 1.0;
    if (diff < 30) {
      exaggeration = 1.8;
    } else if (diff < 60) {
      exaggeration = 1.4;
    } else if (diff < 100) {
      exaggeration = 1.2;
    }

    final double effectiveRange = diff < 50 ? 50 : diff;
    final double forcedMinY = minAlt - (effectiveRange * 0.3 * exaggeration);
    final double forcedMaxY =
        forcedMinY + (effectiveRange * 1.3 * exaggeration);
    final double yRange = forcedMaxY - forcedMinY;

    final double usableWidth = size.width;
    final double chartHeight = size.height - 40; // bottomReserved fixa de 40px
    final double maxDist = distances.last;

    final int start = startIndex < endIndex ? startIndex : endIndex;
    final int end = startIndex < endIndex ? endIndex : startIndex;

    // 2) SEPARACIÓ DE CAMINS MATEMÀTICS (PASAT I FUTUR)
    final pathPast = Path();
    final pathFuture = Path();

    bool hasPastPoints = false;
    bool hasFuturePoints = false;

    // --- CONSTRUCCIÓ DEL POLÍGON DEL PASSAT (ZONA GRADA) ---
    int lastPastIdx = start;
    if (start < realPointsCount) {
      double firstX = (distances[start] / maxDist) * usableWidth;
      pathPast.moveTo(firstX, chartHeight);

      int endPast = end < realPointsCount ? end : realPointsCount - 1;
      for (int i = start; i <= endPast; i++) {
        double x = (distances[i] / maxDist) * usableWidth;
        double relY = (altitudes[i] - forcedMinY) / yRange;
        double y = chartHeight - (relY * chartHeight);
        pathPast.lineTo(x, y);
        lastPastIdx = i;
      }
      double lastPastX = (distances[lastPastIdx] / maxDist) * usableWidth;
      pathPast.lineTo(lastPastX, chartHeight);
      pathPast.close();
      hasPastPoints = true;
    }

    // --- CONSTRUCCIÓ DEL POLÍGON DEL FUTUR (25% FINESTRA DE RUTA) ---
    if (end >= realPointsCount) {
      int startFuture = start >= realPointsCount ? start : realPointsCount - 1;
      double firstFutureX = (distances[startFuture] / maxDist) * usableWidth;
      pathFuture.moveTo(firstFutureX, chartHeight);

      for (int i = startFuture; i <= end; i++) {
        double x = (distances[i] / maxDist) * usableWidth;
        double relY = (altitudes[i] - forcedMinY) / yRange;
        double y = chartHeight - (relY * chartHeight);
        pathFuture.lineTo(x, y);
      }
      double lastFutureX = (distances[end] / maxDist) * usableWidth;
      pathFuture.lineTo(lastFutureX, chartHeight);
      pathFuture.close();
      hasFuturePoints = true;
    }

    // 3) RENDERITZACIÓ AMB ELS TEUS ESTILS A LA PANTALLA
    // Pintem el Passat amb el degradat vertical fluid (Opac dalt, transparent baix)
    if (hasPastPoints) {
      final Rect pastBounds = Rect.fromLTWH(0, 0, usableWidth, chartHeight);
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            trackColor.withAlpha(90), // Color natiu amb opacitat del 35%
            trackColor.withAlpha(0), // Difuminat total a la base
          ],
        ).createShader(pastBounds)
        ..style = PaintingStyle.fill;

      canvas.drawPath(pathPast, gradientPaint);
    }

    // Pintem el Futur amb el format tècnic translúcid gris/blau (10% d'opacitat)
    if (hasFuturePoints) {
      final paintFuture = Paint()
        ..color = Colors.blueGrey
            .withAlpha(26) // Sutil, net i sense carregar el gràfic
        ..style = PaintingStyle.fill;
      canvas.drawPath(pathFuture, paintFuture);
    }
  }

  @override
  bool shouldRepaint(covariant RangeAreaPainter oldDelegate) => true;
}
