// lib/screens/elevations/painters/selection_painter.dart

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

  // Eix global
  final List<double> distances;
  final List<double> altitudes;

  // Waypoints (distàncies globals)
  final List<double>? recordedWaypointGlobalDists;
  final List<double>? importedWaypointGlobalDists;

  // Colors
  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;

  final Color recordedWaypointColor;
  final Color importedWaypointColor;

  static const double bottomReserved = 40.0;
  static const double topReserved = 60.0;
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
    this.recordedWaypointGlobalDists,
    this.importedWaypointGlobalDists,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    final chartHeight = size.height - bottomReserved - topReserved;
    final xAxisY = topReserved + chartHeight;

    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final diff = maxAlt - minAlt;

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
    final maxY = minY + (effectiveRange * 1.3 * exaggeration);
    final yRange = maxY - minY;

    final usableWidth = size.width;
    final maxDist = distances.last;

    double mapX(double dist) {
      if (maxDist == 0) return 0;
      return (dist / maxDist) * usableWidth;
    }

    // WAYPOINTS GRAVATS
    if (recordedWaypointGlobalDists != null &&
        recordedWaypointGlobalDists!.isNotEmpty) {
      final recWpPaint = Paint()
        ..color = recordedWaypointColor
        ..style = PaintingStyle.fill;

      for (final d in recordedWaypointGlobalDists!) {
        final x = mapX(d);
        canvas.drawCircle(Offset(x, xAxisY - 4), 4, recWpPaint);
      }
    }

    // WAYPOINTS IMPORTATS
    if (importedWaypointGlobalDists != null &&
        importedWaypointGlobalDists!.isNotEmpty) {
      final impWpPaint = Paint()
        ..color = importedWaypointColor
        ..style = PaintingStyle.fill;

      for (final d in importedWaypointGlobalDists!) {
        final x = mapX(d);
        canvas.drawCircle(Offset(x, xAxisY - 4), 4, impWpPaint);
      }
    }

    final int? sIndex = startIndex;
    final int? eIndex = endIndex;
    final double? sX = startX;
    final double? eX = endX;

    double dxStart = 0;
    double dxEnd = 0;
    const double tooltipWidth = 80;

    if (sX != null && eX != null) {
      if (_tooltipsOverlap(sX, eX, tooltipWidth)) {
        if (sX < eX) {
          dxStart = -tooltipWidth / 2;
          dxEnd = tooltipWidth / 2;
        } else {
          dxStart = tooltipWidth / 2;
          dxEnd = -tooltipWidth / 2;
        }
      }
    }

    bool inverted = false;
    if (sIndex != null && eIndex != null) {
      inverted = sIndex > eIndex;
    }

    if (graphX != null && graphIndex != null) {
      _paintMainNeedle(
        canvas: canvas,
        size: size,
        x: graphX!,
        index: graphIndex!,
        minY: minY,
        yRange: yRange,
        chartHeight: chartHeight,
        xAxisY: xAxisY,
        tooltipColor: graphNeedleColor.withAlpha(230),
      );
    }

    if (startX != null && startIndex != null) {
      _paintRangeNeedle(
        canvas,
        size,
        startX!,
        startIndex!,
        inverted ? sliderEndNeedleColor : sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        dx: dxStart,
        showTooltip: true,
        tooltipColor: inverted
            ? Colors.red.withAlpha(230)
            : Colors.green.withAlpha(230),
      );
    }

    if (endX != null && endIndex != null) {
      _paintRangeNeedle(
        canvas,
        size,
        endX!,
        endIndex!,
        inverted ? sliderStartNeedleColor : sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        dx: dxEnd,
        showTooltip: true,
        tooltipColor: inverted
            ? Colors.green.withAlpha(230)
            : Colors.red.withAlpha(230),
      );
    }
  }

  void _paintMainNeedle({
    required Canvas canvas,
    required Size size,
    required double x,
    required int index,
    required double minY,
    required double yRange,
    required double chartHeight,
    required double xAxisY,
    required Color tooltipColor,
  }) {
    if (index < 0 || index >= altitudes.length) return;

    final double distMeters = distances[index];
    final double distKm = distMeters / 1000.0;
    final double altPrimary = altitudes[index];

    final double relPrimary = (altPrimary - minY) / yRange;
    final double dyPrimary =
        topReserved + (chartHeight - (relPrimary * chartHeight));

    final linePaint = Paint()
      ..color = graphNeedleColor.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, xAxisY), Offset(x, dyPrimary), linePaint);

    final dotPaintPrimary = Paint()..color = graphNeedleColor;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, dyPrimary), dotRadius, dotPaintPrimary);
    canvas.drawCircle(Offset(x, dyPrimary), dotRadius, dotBorderPaint);

    _paintTooltipBox(
      canvas,
      size,
      x,
      "${altPrimary.toStringAsFixed(0)} m\n${distKm.toStringAsFixed(2)} km",
      tooltipColor,
    );
  }

  void _paintRangeNeedle(
    Canvas canvas,
    Size size,
    double x,
    int index,
    Color color,
    double minY,
    double yRange,
    double chartHeight,
    double xAxisY, {
    double dx = 0,
    bool showTooltip = true,
    required Color tooltipColor,
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

    final dotPaint = Paint()..color = color;
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, dy), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x, dy), dotRadius, dotBorder);

    if (showTooltip) {
      _paintTooltipBox(
        canvas,
        size,
        x + dx,
        "${alt.toStringAsFixed(0)} m\n${distKm.toStringAsFixed(2)} km",
        tooltipColor,
      );
    }
  }

  void _paintTooltipBox(
    Canvas canvas,
    Size size,
    double x,
    String text,
    Color bgColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final double w = textPainter.width + 16;
    final double h = textPainter.height + 12;

    double rectX = x - w / 2;
    double rectY = 4;

    const double padding = 4.0;
    rectX = rectX.clamp(padding, size.width - w - padding);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectX, rectY, w, h),
      const Radius.circular(8),
    );

    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(rrect, bg);
    textPainter.paint(canvas, Offset(rectX + 8, rectY + 6));
  }

  bool _tooltipsOverlap(double x1, double x2, double width) {
    return (x1 - x2).abs() < width;
  }

  @override
  bool shouldRepaint(covariant SelectionPainter old) => true;
}
