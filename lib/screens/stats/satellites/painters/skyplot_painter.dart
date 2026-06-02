// lib/stats/satellites/painters/skyplot_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SkyplotPainter extends CustomPainter {
  final List<dynamic> satellites;
  final Map<String, String> Function(int, int) parseFn;

  SkyplotPainter({required this.satellites, required this.parseFn});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. DIBUIXAR ELS CERCLES CONCÈNTRICS D'ELEVACIÓ
    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.33, gridPaint);

    // 2. DIBUIXAR LES LÍNIES DELS EJES CARDINALS (N-S, E-O)
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      gridPaint,
    );

    // 3. COL·LOCAR LES LLETRES DELS PUNTS CARDINALS
    final cardinals = {
      'N': Offset(center.dx - 5, 2),
      'S': Offset(center.dx - 5, size.height - 14),
      'E': Offset(size.width - 14, center.dy - 7),
      'O': Offset(2, center.dy - 7),
    };

    cardinals.forEach((key, value) {
      textPainter.text = TextSpan(
        text: key,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, value);
    });

    // 4. PINTAR CADA SATÈL·LIT EN LA SEVA COORDENADA POLAR
    for (var sat in satellites) {
      final map = Map<String, dynamic>.from(sat);
      final azimuth = (map['azimuth'] as num).toDouble();
      final elevation = (map['elevation'] as num).toDouble();
      final usedInFix = map['usedInFix'] as bool;
      final parsed = parseFn(map['constellation'] as int, map['svid'] as int);

      final double distanceFactor = (90.0 - elevation) / 90.0;
      final double targetRadius = radius * distanceFactor;

      final double angleRad = (azimuth - 90.0) * math.pi / 180.0;

      final double satX = center.dx + targetRadius * math.cos(angleRad);
      final double satY = center.dy + targetRadius * math.sin(angleRad);

      final dotColor = usedInFix ? Colors.green : Colors.grey.withAlpha(160);

      canvas.drawCircle(Offset(satX, satY), 8.0, Paint()..color = dotColor);
      canvas.drawCircle(
        Offset(satX, satY),
        8.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      textPainter.text = TextSpan(
        text: parsed['code']!,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(satX - (textPainter.width / 2), satY - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkyplotPainter oldDelegate) => true;
}
