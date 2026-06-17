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

    // 1. DIBUJAR RADAR: Círculos concéntricos de elevación (45°, 60°, 75°)
    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.33, gridPaint);

    // Líneas de los ejes cardinales y diagonales (N-S, E-O, NW-SE, NE-SW)
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

    // Grados de elevación impresos de fondo
    final elevationLabels = {
      '45°': radius * 0.82,
      '60°': radius * 0.52,
      '75°': radius * 0.22,
    };
    elevationLabels.forEach((label, offsetFromCenter) {
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx + offsetFromCenter, center.dy + 4),
      );
    });

    // 2. TEXTOS CARDINALES (N, S, E, O, NW, NE, SW, SE)
    final cardinals = {
      'N': Offset(center.dx - 4, 2),
      'S': Offset(center.dx - 4, size.height - 14),
      'E': Offset(size.width - 12, center.dy - 6),
      'O': Offset(2, center.dy - 6),
      'NE': Offset(center.dx + (radius * 0.65), center.dy - (radius * 0.75)),
      'NW': Offset(center.dx - (radius * 0.78), center.dy - (radius * 0.75)),
      'SE': Offset(center.dx + (radius * 0.65), center.dy + (radius * 0.68)),
      'SW': Offset(center.dx - (radius * 0.78), center.dy + (radius * 0.68)),
    };

    cardinals.forEach((key, value) {
      textPainter.text = TextSpan(
        text: key,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, value);
    });

    // 3. PINTAR NODOS GEOMÉTRICOS DE CADA SATÉLITE
    for (var sat in satellites) {
      final map = Map<String, dynamic>.from(sat);
      final azimuth = (map['azimuth'] as num).toDouble();
      final elevation = (map['elevation'] as num).toDouble();
      final cn0 = (map['cn0'] as num).toDouble();
      final parsed = parseFn(map['constellation'] as int, map['svid'] as int);

      final double distanceFactor = (90.0 - elevation) / 90.0;
      final double targetRadius = radius * distanceFactor;
      final double angleRad = (azimuth - 90.0) * math.pi / 180.0;

      final double satX = center.dx + targetRadius * math.cos(angleRad);
      final double satY = center.dy + targetRadius * math.sin(angleRad);

      // Asignación de colores real de tu imagen según decibelios
      Color satColor = Colors.orange;
      if (cn0 >= 30.0) {
        satColor = Colors.green;
      } else if (cn0 >= 20.0)
        satColor = Colors.amber;

      final paintNode = Paint()
        ..color = satColor
        ..style = PaintingStyle.fill;
      final paintStroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Dibujar la figura según la red (1=GPS, 3=GLONASS, 6=GALILEO, 5=BEIDOU)
      final constellationType = map['constellation'] as int;
      canvas.save();
      canvas.translate(satX, satY);

      if (constellationType == 1) {
        // Círculo para GPS
        canvas.drawCircle(Offset.zero, 7.0, paintNode);
        canvas.drawCircle(Offset.zero, 7.0, paintStroke);
      } else if (constellationType == 3) {
        // Cuadrado para GLONASS
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 12, height: 12),
          paintNode,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 12, height: 12),
          paintStroke,
        );
      } else if (constellationType == 6) {
        // Triángulo para GALILEO
        var path = Path()
          ..moveTo(0, -8)
          ..lineTo(7, 6)
          ..lineTo(-7, 6)
          ..close();
        canvas.drawPath(path, paintNode);
        canvas.drawPath(path, paintStroke);
      } else {
        // Rombo para BeiDou / Otros
        var path = Path()
          ..moveTo(0, -8)
          ..lineTo(6, 0)
          ..lineTo(0, 8)
          ..lineTo(-6, 0)
          ..close();
        canvas.drawPath(path, paintNode);
        canvas.drawPath(path, paintStroke);
      }
      canvas.restore();

      // Imprimir el código identificador (G12, R76...) justo encima o al lado de la figura
      textPainter.text = TextSpan(
        text: parsed['code']!,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(satX - (textPainter.width / 2), satY - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkyplotPainter oldDelegate) => true;
}
