import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  // Agulla principal
  final double? graphX;
  final int? graphIndex;

  // Rang
  final double? startX;
  final int? startIndex;
  final double? endX;
  final int? endIndex;

  // Track primari
  final List<double> distances;
  final List<double> altitudes;

  // Track secundari
  final List<double>? secondaryDistances;
  final List<double>? secondaryAltitudes;

  // Colors
  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;
  final Color? secondaryGraphNeedleColor;

  static const double bottomReserved = 40.0; // per labels X
  static const double topReserved = 60.0; // espai per tooltips
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
    this.secondaryDistances,
    this.secondaryAltitudes,
    this.secondaryGraphNeedleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    // Alçada real del gràfic (sense tooltips ni labels)
    final chartHeight = size.height - bottomReserved - topReserved;

    // Posició de l’eix X (base del perfil)
    final xAxisY = topReserved + chartHeight;

    // Rang vertical combinat
    final List<double> allAlts = [
      ...altitudes,
      if (secondaryAltitudes != null) ...secondaryAltitudes!,
    ];

    final double minAlt = allAlts.reduce((a, b) => a < b ? a : b);
    final double maxAlt = allAlts.reduce((a, b) => a > b ? a : b);

    double diff = maxAlt - minAlt;
    double effectiveRange = diff < 50 ? 50 : diff;

    final double minY = minAlt - (effectiveRange * 0.1);
    final double maxY = minY + (effectiveRange * 1.2);
    final double yRange = maxY - minY;

    bool showRangeText = true;
    if (startX != null && endX != null) {
      if ((endX! - startX!).abs() < 60) {
        showRangeText = false;
      }
    }

    // --- AGULLA PRINCIPAL ---
    if (graphX != null && graphIndex != null) {
      _paintMainNeedle(
        canvas: canvas,
        x: graphX!,
        index: graphIndex!,
        minY: minY,
        yRange: yRange,
        chartHeight: chartHeight,
        xAxisY: xAxisY,
      );
    }

    // --- AGULLA INICI RANG ---
    if (startX != null && startIndex != null) {
      _paintRangeNeedle(
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

    // --- AGULLA FINAL RANG ---
    if (endX != null && endIndex != null) {
      _paintRangeNeedle(
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

  // ------------------------------------------------------------
  //  AGULLA PRINCIPAL
  // ------------------------------------------------------------
  void _paintMainNeedle({
    required Canvas canvas,
    required double x,
    required int index,
    required double minY,
    required double yRange,
    required double chartHeight,
    required double xAxisY,
  }) {
    if (index < 0 || index >= altitudes.length) return;

    final double distMeters = distances[index];
    final double distKm = distMeters / 1000.0;
    final double altPrimary = altitudes[index];

    final double relPrimary = (altPrimary - minY) / yRange;
    final double dyPrimary =
        topReserved + (chartHeight - (relPrimary * chartHeight));

    // Línia vertical
    final linePaint = Paint()
      ..color = graphNeedleColor.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, xAxisY), Offset(x, dyPrimary), linePaint);

    // Punt principal
    final dotPaintPrimary = Paint()..color = graphNeedleColor;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, dyPrimary), dotRadius, dotPaintPrimary);
    canvas.drawCircle(Offset(x, dyPrimary), dotRadius, dotBorderPaint);

    // Punt secundari
    if (secondaryDistances != null &&
        secondaryAltitudes != null &&
        secondaryGraphNeedleColor != null) {
      final double? altSecondary = _interpolateAltitude(
        secondaryDistances!,
        secondaryAltitudes!,
        distMeters,
      );

      if (altSecondary != null) {
        final double relSec = (altSecondary - minY) / yRange;
        final double dySec =
            topReserved + (chartHeight - (relSec * chartHeight));

        final dotPaintSecondary = Paint()..color = secondaryGraphNeedleColor!;
        canvas.drawCircle(Offset(x, dySec), dotRadius, dotPaintSecondary);
        canvas.drawCircle(Offset(x, dySec), dotRadius, dotBorderPaint);
      }
    }

    // TOOLTIP
    final String text =
        "${altPrimary.toStringAsFixed(0)} m\n${distKm.toStringAsFixed(2)} km";

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final rectW = textPainter.width + 14;
    final rectH = textPainter.height + 10;
    final rectX = x - rectW / 2;
    double rectY = dyPrimary - rectH - 14;

    if (rectY < 4) rectY = 4;

    final bgPaint = Paint()..color = graphNeedleColor.withAlpha(230);
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectX, rectY, rectW, rectH),
      const Radius.circular(6),
    );

    canvas.drawRRect(rRect, bgPaint);
    textPainter.paint(canvas, Offset(rectX + 7, rectY + 5));
  }

  // ------------------------------------------------------------
  //  AGULLES DE RANG
  // ------------------------------------------------------------
  void _paintRangeNeedle(
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
    final distMeters = distances[index];
    final distKm = distMeters / 1000.0;

    final double rel = (alt - minY) / yRange;
    final double dy = topReserved + (chartHeight - (rel * chartHeight));

    final linePaint = Paint()
      ..color = color.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, xAxisY), Offset(x, dy), linePaint);

    if (showText) {
      final String text =
          "${alt.toStringAsFixed(0)} m\n${distKm.toStringAsFixed(2)} km";

      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final rectW = textPainter.width + 14;
      final rectH = textPainter.height + 10;
      final rectX = x - rectW / 2;
      double rectY = dy - rectH - 14;

      if (rectY < 4) rectY = 4;

      final bgPaint = Paint()..color = color.withAlpha(230);
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rectX, rectY, rectW, rectH),
        const Radius.circular(6),
      );

      canvas.drawRRect(rRect, bgPaint);
      textPainter.paint(canvas, Offset(rectX + 7, rectY + 5));
    }

    final dotPaint = Paint()..color = color;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, dy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x, dy), dotRadius, dotBorderPaint);
  }

  // ------------------------------------------------------------
  //  INTERPOLACIÓ ALTITUD TRACK SECUNDARI
  // ------------------------------------------------------------
  double? _interpolateAltitude(
    List<double> dists,
    List<double> alts,
    double target,
  ) {
    if (target < dists.first || target > dists.last) return null;

    int i = 0;
    while (i < dists.length - 1 && dists[i + 1] < target) {
      i++;
    }

    final d1 = dists[i];
    final d2 = dists[i + 1];
    final a1 = alts[i];
    final a2 = alts[i + 1];

    if ((d2 - d1).abs() < 0.0001) return a1;

    final t = (target - d1) / (d2 - d1);
    return a1 + (a2 - a1) * t;
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
        old.secondaryDistances != secondaryDistances ||
        old.secondaryAltitudes != secondaryAltitudes ||
        old.graphNeedleColor != graphNeedleColor ||
        old.sliderStartNeedleColor != sliderStartNeedleColor ||
        old.sliderEndNeedleColor != sliderEndNeedleColor ||
        old.secondaryGraphNeedleColor != secondaryGraphNeedleColor;
  }
}
