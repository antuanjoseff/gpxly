import 'package:flutter/material.dart';

class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter({this.squareSize = 8});

  final double squareSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        final isDark = ((x ~/ squareSize) + (y ~/ squareSize)) % 2 == 0;

        paint.color = isDark ? Colors.grey.shade300 : Colors.grey.shade100;

        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) {
    return oldDelegate.squareSize != squareSize;
  }
}
