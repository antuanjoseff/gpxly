import 'package:flutter/material.dart';

class RangeHighlightPainter extends CustomPainter {
  final RangeValues range;
  final Color color;

  RangeHighlightPainter({required this.range, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final startX = range.start * size.width;
    final endX = range.end * size.width;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTRB(startX, 0, endX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant RangeHighlightPainter oldDelegate) {
    return oldDelegate.range != range || oldDelegate.color != color;
  }
}
