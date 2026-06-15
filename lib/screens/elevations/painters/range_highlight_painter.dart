import 'package:flutter/material.dart';
import 'dart:math' as math;

class RangeHighlightPainter extends CustomPainter {
  final double? startX;
  final double? endX;
  final Color color;
  final double bottomReserved;

  // 🟢 CORREGIT: Marquem bottomReserved com a requerit pur i sense valors inventats
  RangeHighlightPainter({
    required this.startX,
    required this.endX,
    required this.color,
    required this.bottomReserved,
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
  final int realPointsCount;
  final Color trackColor;

  // Marquem les mateixes constants de reserva de dalt i baix que utilitza el SelectionPainter
  final double topReserved;
  final double bottomReserved;

  RangeAreaPainter({
    required this.startIndex,
    required this.endIndex,
    required this.distances,
    required this.altitudes,
    required this.realPointsCount,
    required this.trackColor,
    required this.topReserved,
    required this.bottomReserved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    // 1) Calculem els espais verticals exactament igual que al SelectionPainter
    final chartHeight = size.height - bottomReserved - topReserved;
    final xAxisY = topReserved + chartHeight;

    // 2) Lògica d'escalat vertical de cotes (La teva fórmula exacta de Senda)
    final double minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final double maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final double diff = (maxAlt - minAlt).abs();

    double exaggeration = 1.0;
    if (diff < 30) {
      exaggeration = 1.8;
    } else if (diff < 60) {
      exaggeration = 1.4;
    } else if (diff < 100) {
      exaggeration = 1.2;
    }

    final effectiveRange = diff < 50 ? 50 : diff;
    final minY = minAlt - (effectiveRange * 0.3 * exaggeration);

    final maxY = minY + (effectiveRange * 1.62 * exaggeration);
    final yRange = maxY - minY;

    final usableWidth = size.width;
    final maxDist = distances.last;

    // Funcions de mapeig de coordenades reals a píxels de pantalla
    double mapX(double dist) {
      if (maxDist == 0) return 0;
      return (dist / maxDist) * usableWidth;
    }

    double mapY(double alt) {
      if (yRange == 0) return xAxisY;
      final double rel = (alt - minY) / yRange;
      return topReserved + (chartHeight - (rel * chartHeight));
    }

    // 3) 🛡️ CONTROL ANTI-SWAP DE SEGURETAT
    // Trobem quin índex és el més petit i quin és el més gran per si l'usuari els creua
    final int startIdx = math
        .min(startIndex, endIndex)
        .clamp(0, altitudes.length - 1);
    final int endIdx = math
        .max(startIndex, endIndex)
        .clamp(0, altitudes.length - 1);

    if (startIdx == endIdx) return;

    // 4) 📐 CREACIÓ DEL CAMÍ DE LA SILUETA DEL TRAM SELECCIONAT
    final path = Path();

    // Punt inicial: A l'eix X (a baix), a la distància on comença el tram
    final double firstX = mapX(distances[startIdx]);
    path.moveTo(firstX, xAxisY);

    // Pujada i recorregut: Resseguim la línia de la muntanya punt per punt del tram
    for (int i = startIdx; i <= endIdx; i++) {
      final double x = mapX(distances[i]);
      final double y = mapY(altitudes[i]);
      path.lineTo(x, y);
    }

    // Baixada: Des de l'últim punt alt de la muntanya recta cap a l'eix X (a baix)
    final double lastX = mapX(distances[endIdx]);
    path.lineTo(lastX, xAxisY);

    // Tancat: Tornem en línia recta per sobre de l'eix X fins al punt inicial
    path.close();

    // 5) 🎨 CONFIGURACIÓ DEL PINZELL DE FARCIT (AMB DEGRADAT)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [trackColor.withAlpha(191), trackColor.withAlpha(38)],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTRB(firstX, topReserved, lastX, xAxisY),
      )
      ..style = PaintingStyle.fill;

    // Dibuixem la silueta de la muntanya retallada a sobre del llenç
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RangeAreaPainter oldDelegate) {
    return oldDelegate.startIndex != startIndex ||
        oldDelegate.endIndex != endIndex ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.distances != distances ||
        oldDelegate.altitudes != altitudes;
  }
}
