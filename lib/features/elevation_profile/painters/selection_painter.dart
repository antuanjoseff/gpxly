import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  final double? graphX;
  final int? graphIndex;

  final double? startX;
  final int? startIndex;

  final double? endX;
  final int? endIndex;

  final List<double> distances;
  final List<double> altitudes;

  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;

  static const double horizontalPadding = 24.0;
  static const double bottomReserved = 40.0; // com els bottomTitles
  static const double dotRadius = 5.0;

  SelectionPainter({
    required this.graphX,
    required this.graphIndex,
    required this.startX,
    required this.startIndex,
    required this.endX,
    required this.endIndex,
    required this.distances,
    required this.altitudes,
    required this.graphNeedleColor,
    required this.sliderStartNeedleColor,
    required this.sliderEndNeedleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    final left = horizontalPadding;
    final right = size.width - horizontalPadding;

    // Alçada útil del gràfic (coherent amb FLChart + bottomTitles 40)
    final chartHeight = size.height - bottomReserved;
    final xAxisY = chartHeight;

    // Rang vertical FLChart-like
    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final range = maxAlt - minAlt;
    final minY = minAlt - range * 0.1;
    final maxY = maxAlt + range * 0.1;
    final yRange = maxY - minY;

    if (graphX != null && graphIndex != null) {
      _paintNeedle(
        canvas,
        graphX!.clamp(left, right),
        graphIndex!,
        graphNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }

    if (startX != null && startIndex != null) {
      _paintNeedle(
        canvas,
        startX!.clamp(left, right),
        startIndex!,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }

    if (endX != null && endIndex != null) {
      _paintNeedle(
        canvas,
        endX!.clamp(left, right),
        endIndex!,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }
  }

  void _paintNeedle(
    Canvas canvas,
    double x,
    int index,
    Color color,
    double minY,
    double yRange,
    double chartHeight,
    double xAxisY,
  ) {
    if (index < 0 || index >= altitudes.length) return;

    final alt = altitudes[index];

    // 🔥 CANVI CLAU: Normalització exacta
    // Multipliquem l'altitud per l'alçada real del gràfic
    final double relativePos = (alt - minY) / yRange;
    final double dy = chartHeight - (relativePos * chartHeight);

    final linePaint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x, xAxisY), Offset(x, dy), linePaint);

    // El cercle exactament al final de la línia (dy)
    canvas.drawCircle(Offset(x, dy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x, dy), dotRadius, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter old) {
    return old.graphX != graphX ||
        old.startX != startX ||
        old.endX != endX ||
        old.graphIndex != graphIndex ||
        old.startIndex != startIndex ||
        old.endIndex != endIndex ||
        old.distances != distances ||
        old.altitudes != altitudes ||
        old.graphNeedleColor != graphNeedleColor ||
        old.sliderStartNeedleColor != sliderStartNeedleColor ||
        old.sliderEndNeedleColor != sliderEndNeedleColor;
  }
}
