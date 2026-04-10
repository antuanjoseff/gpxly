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

    // Alçada útil del gràfic (coherent amb FLChart + bottomTitles 40)
    final chartHeight = size.height - bottomReserved;
    final xAxisY = chartHeight;

    // 1. Busquem els valors reals
    final double actualMinAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final double actualMaxAlt = altitudes.reduce((a, b) => a > b ? a : b);

    // 2. Calculem la diferència real
    double diff = actualMaxAlt - actualMinAlt;

    // 3. 🔥 EL CANVI CLAU: Establim un rang mínim de seguretat
    // Si la diferència és menor a 50m, forcem que el rang de treball sigui 50.
    // Això farà que les petites variacions GPS semblin gairebé planes.
    double effectiveRange = diff < 50 ? 50 : diff;

    // 4. Calculem el minY i maxY basant-nos en aquest rang efectiu
    // Si el terreny és molt planer, centrem el rang perquè la línia quedi al mig
    final double minY = actualMinAlt - (effectiveRange * 0.1);
    final double maxY =
        minY +
        (effectiveRange * 1.2); // 1.2 per donar el 10% de marge dalt i baix
    final double yRange = maxY - minY;

    bool showRangeText = true;
    if (startX != null && endX != null) {
      // Si estan a menys de 60 píxels, no mostrem el text sobre el gràfic
      // perquè ja el veurem a la barra de dades de sota.
      if ((endX! - startX!).abs() < 60) {
        showRangeText = false;
      }
    }

    // AGULLA DE DRAG SIMPLE (Sempre amb text)
    if (graphX != null && graphIndex != null) {
      _paintNeedle(
        canvas,
        graphX!,
        graphIndex!,
        graphNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        showText: true,
      );
    }

    // AGULLA INICI RANG
    if (startX != null && startIndex != null) {
      _paintNeedle(
        canvas,
        startX!,
        startIndex!,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        showText: showRangeText,
      );
    }

    // AGULLA FINAL RANG
    if (endX != null && endIndex != null) {
      _paintNeedle(
        canvas,
        endX!,
        endIndex!,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        showText: showRangeText,
      );
    }
  }

  // void _paintNeedle(
  //   Canvas canvas,
  //   double x,
  //   int index,
  //   Color color,
  //   double minY,
  //   double yRange,
  //   double chartHeight,
  //   double xAxisY,
  // ) {
  //   if (index < 0 || index >= altitudes.length) return;

  //   final alt = altitudes[index];

  //   // 🔥 CANVI CLAU: Normalització exacta
  //   // Multipliquem l'altitud per l'alçada real del gràfic
  //   final double relativePos = (alt - minY) / yRange;
  //   final double dy = chartHeight - (relativePos * chartHeight);

  //   final linePaint = Paint()
  //     ..color = color.withAlpha(180)
  //     ..strokeWidth = 2;

  //   final dotPaint = Paint()
  //     ..color = color
  //     ..style = PaintingStyle.fill;

  //   final dotBorderPaint = Paint()
  //     ..color = Colors.white
  //     ..strokeWidth = 2
  //     ..style = PaintingStyle.stroke;

  //   canvas.drawLine(Offset(x, xAxisY), Offset(x, dy), linePaint);

  //   // El cercle exactament al final de la línia (dy)
  //   canvas.drawCircle(Offset(x, dy), dotRadius, dotPaint);
  //   canvas.drawCircle(Offset(x, dy), dotRadius, dotBorderPaint);
  // }

  void _paintNeedle(
    Canvas canvas,
    double x,
    int index,
    Color color,
    double minY,
    double yRange,
    double chartHeight,
    double xAxisY, {
    required bool showText,
  }) {
    if (index < 0 || index >= altitudes.length) return;

    final alt = altitudes[index];
    final dist = distances[index];

    final double relativePos = (alt - minY) / yRange;
    final double dy = chartHeight - (relativePos * chartHeight);

    // 1. Dibuixar la línia vertical (Sempre es dibuixa)
    final linePaint = Paint()
      ..color = color.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, xAxisY), Offset(x, dy), linePaint);

    // 2. Dibuixar l'etiqueta de text (NOMÉS si showText és true)
    if (showText) {
      final String text =
          "${alt.toStringAsFixed(0)}m\n${dist.toStringAsFixed(1)}km";
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final rectW = textPainter.width + 12;
      final rectH = textPainter.height + 8;
      final rectX = x - (rectW / 2);
      final rectY = dy - rectH - 12;

      final backgroundPaint = Paint()..color = color.withAlpha(230);
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rectX, rectY, rectW, rectH),
        const Radius.circular(6),
      );

      canvas.drawRRect(rRect, backgroundPaint);
      textPainter.paint(canvas, Offset(rectX + 6, rectY + 4));
    }

    // 3. Dibuixar el punt (Sempre es dibuixa)
    final dotPaint = Paint()..color = color;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

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
