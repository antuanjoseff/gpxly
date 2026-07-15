// lib/screens/elevations/painters/selection_painter.dart
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

  final List<double>? recordedWaypointGlobalDists;
  final List<double>? importedWaypointGlobalDists;

  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;
  final Color recordedWaypointColor;
  final Color importedWaypointColor;

  final double topReserved; // És 0.0
  final double bottomReserved; // Són 16.0
  final double minY;
  final double maxY;
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
    required this.recordedWaypointColor,
    required this.importedWaypointColor,
    required this.topReserved,
    required this.bottomReserved,
    required this.minY,
    required this.maxY,
    this.recordedWaypointGlobalDists,
    this.importedWaypointGlobalDists,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    final chartHeight = size.height - bottomReserved - topReserved;
    final xAxisY = topReserved + chartHeight;
    final double yRange = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    final usableWidth = size.width;
    final maxDist = distances.last;

    double mapX(double dist) {
      if (maxDist == 0) return 0;
      return (dist / maxDist) * usableWidth;
    }

    // WAYPOINTS NOMÉS AL TERRA (EIX X)
    if (recordedWaypointGlobalDists != null) {
      final recWpPaint = Paint()
        ..color = recordedWaypointColor
        ..style = PaintingStyle.fill;
      for (final d in recordedWaypointGlobalDists!) {
        canvas.drawCircle(Offset(mapX(d), xAxisY), 4, recWpPaint);
      }
    }
    if (importedWaypointGlobalDists != null) {
      final impWpPaint = Paint()
        ..color = importedWaypointColor
        ..style = PaintingStyle.fill;
      for (final d in importedWaypointGlobalDists!) {
        canvas.drawCircle(Offset(mapX(d), xAxisY), 4, impWpPaint);
      }
    }

    final bool isCrossed = (startX != null && endX != null)
        ? endX! < startX!
        : false;

    // 1. AGUJA ESQUERRA (Verda)
    if (startX != null &&
        startIndex != null &&
        endX != null &&
        endIndex != null) {
      _paintNeedleLineAndDot(
        canvas,
        isCrossed ? endX! : startX!,
        isCrossed ? endIndex! : startIndex!,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    } else if (startX != null && startIndex != null) {
      _paintNeedleLineAndDot(
        canvas,
        startX!,
        startIndex!,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }

    // 2. AGUJA DRETA (Vermella)
    if (startX != null &&
        startIndex != null &&
        endX != null &&
        endIndex != null) {
      _paintNeedleLineAndDot(
        canvas,
        isCrossed ? startX! : endX!,
        isCrossed ? startIndex! : endIndex!,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    } else if (endX != null && endIndex != null) {
      _paintNeedleLineAndDot(
        canvas,
        endX!,
        endIndex!,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }

    // 3. AGUJA CENTRAL (Dit Blau)
    if (graphX != null && graphIndex != null) {
      _paintNeedleLineAndDot(
        canvas,
        graphX!,
        graphIndex!,
        graphNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
    }
  }

  void _paintNeedleLineAndDot(
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

    // 🚀 LA CORRECCIÓ MATEMÀTICA CLAU:
    // Invertim la posició relativa de forma estricta (1.0 - rel) multiplicant per l'alçada útil
    // i sumant el topReserved, clavant el node a sobre del dibuix real de fl_chart.
    final double rel = (altitudes[index] - minY) / yRange;
    final double dy = topReserved + (chartHeight * (1.0 - rel.clamp(0.0, 1.0)));

    final linePaint = Paint()
      ..color = color.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, xAxisY), Offset(x, dy), linePaint);

    final dotPaint = Paint()..color = color;
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(x, dy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x, dy), dotRadius, dotBorder);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) => true;
}
