import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  final GlobalKey chartKey;
  final List<double> distances;
  final List<double> altitudes;
  final int selectedIndex;
  final Color lineColor;
  final Color dotColor;
  final Color dotBorderColor;
  final bool isSliderActive;

  SelectionPainter({
    required this.chartKey,
    required this.distances,
    required this.altitudes,
    required this.selectedIndex,
    required this.lineColor,
    required this.dotColor,
    required this.dotBorderColor,
    required this.isSliderActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isSliderActive) return;

    final box = chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final chartSize = box.size;

    final maxDist = distances.last;
    final x = (distances[selectedIndex] / maxDist) * chartSize.width;

    final double bottomPadding = 40;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final dotPaint = Paint()..color = dotColor;

    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, chartSize.height - bottomPadding),
      linePaint,
    );

    final y = _altitudeToY(
      altitudes[selectedIndex],
      altitudes,
      chartSize.height - bottomPadding,
    );

    canvas.drawCircle(Offset(x, y), 4, dotPaint);
    canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
  }

  double _altitudeToY(double alt, List<double> alts, double height) {
    final minAlt = alts.reduce((a, b) => a < b ? a : b);
    final maxAlt = alts.reduce((a, b) => a > b ? a : b);
    final norm = (alt - minAlt) / (maxAlt - minAlt);
    return height - (norm * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
