// lib/screens/elevations/painters/selection_painter.dart (BLOC 1 DE 2)
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
  final Color sliderStartNeedleColor; // Color Verd original
  final Color sliderEndNeedleColor; // Color Vermell original

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
        canvas.drawCircle(Offset(mapX(d), xAxisY - 4), 4, recWpPaint);
      }
    }

    // WAYPOINTS IMPORTATS
    if (importedWaypointGlobalDists != null &&
        importedWaypointGlobalDists!.isNotEmpty) {
      final impWpPaint = Paint()
        ..color = importedWaypointColor
        ..style = PaintingStyle.fill;
      for (final d in importedWaypointGlobalDists!) {
        canvas.drawCircle(Offset(mapX(d), xAxisY - 4), 4, impWpPaint);
      }
    }

    final int? sIndex = startIndex;
    final int? eIndex = endIndex;
    final double? sX = startX;
    final double? eX = endX;

    // ─────────────────────────────────────────────────────────────────────────
    // 🧮 LÒGICA DE REVERSIBILITAT GEOMÈTRICA DE SENDA (Inversió de Punts)
    // ─────────────────────────────────────────────────────────────────────────
    // Determinem si l'usuari ha creuat els dits (Final menor que l'Inici)
    bool isCrossed = false;
    if (sX != null && eX != null) {
      isCrossed = eX < sX;
    }

    // 1. DIBUIX DE L'AGULLA DE L'ESQUERRA (Sempre es pinta en VERD)
    if (sX != null && sIndex != null && eX != null && eIndex != null) {
      // Si s'han creuat, l'agulla de l'esquerra real és la del final (eX)
      final double leftX = isCrossed ? eX : sX;
      final int leftIndex = isCrossed ? eIndex : sIndex;

      _paintNeedleLineAndDot(
        canvas,
        leftX,
        leftIndex,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );

      // El tooltip de l'esquerra mostra sempre la info de l'agulla de l'esquerra en VERD
      final distKm = distances[leftIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[leftIndex].toStringAsFixed(0)} m",
        sliderStartNeedleColor.withAlpha(230),
        forceLeft: true,
      );
    } else if (sX != null && sIndex != null) {
      // Cas de seguretat si només s'ha pintat l'inici
      _paintNeedleLineAndDot(
        canvas,
        sX,
        sIndex,
        sliderStartNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
      final distKm = distances[sIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[sIndex].toStringAsFixed(0)} m",
        sliderStartNeedleColor.withAlpha(230),
        forceLeft: true,
      );
    }

    // 2. DIBUIX DE L'AGULLA DE LA DRETA (Sempre es pinta en VERMELL)
    if (sX != null && sIndex != null && eX != null && eIndex != null) {
      // Si s'han creuat, l'agulla de la dreta real és la de l'inici (sX)
      final double rightX = isCrossed ? sX : eX;
      final int rightIndex = isCrossed ? sIndex : eIndex;

      _paintNeedleLineAndDot(
        canvas,
        rightX,
        rightIndex,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );

      // El tooltip de la dreta mostra sempre la info de l'agulla de la dreta en VERMELL
      final distKm = distances[rightIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[rightIndex].toStringAsFixed(0)} m",
        sliderEndNeedleColor.withAlpha(230),
        forceLeft: false,
      );
    } else if (eX != null && eIndex != null) {
      // Cas de seguretat si només s'ha pintat el final
      _paintNeedleLineAndDot(
        canvas,
        eX,
        eIndex,
        sliderEndNeedleColor,
        minY,
        yRange,
        chartHeight,
        xAxisY,
      );
      final distKm = distances[eIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[eIndex].toStringAsFixed(0)} m",
        sliderEndNeedleColor.withAlpha(230),
        forceLeft: false,
      );
    }

    // 3. L'agulla central del dit (S'ARROSSEGA FLUIDA SOTA EL DIT INDEPENDENT!)
    if (graphX != null && graphIndex != null) {
      _paintMainNeedle(
        canvas,
        size,
        graphX!,
        graphIndex!,
        minY,
        yRange,
        chartHeight,
        xAxisY,
        graphNeedleColor.withAlpha(230),
      );
    }
  }

  // lib/screens/elevations/painters/selection_painter.dart (BLOC 2 DE 2)
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
    final double rel = (altitudes[index] - minY) / yRange;
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
  }

  void _paintMainNeedle(
    Canvas canvas,
    Size size,
    double x,
    int index,
    double minY,
    double yRange,
    double chartHeight,
    double xAxisY,
    Color tooltipColor,
  ) {
    if (index < 0 || index >= altitudes.length) return;
    _paintNeedleLineAndDot(
      canvas,
      x,
      index,
      graphNeedleColor,
      minY,
      yRange,
      chartHeight,
      xAxisY,
    );

    final double distKm = distances[index] / 1000.0;
    _paintDynamicTooltipBox(
      canvas,
      size,
      x,
      "${distKm.toStringAsFixed(2)} km  |  ${altitudes[index].toStringAsFixed(0)} m",
      tooltipColor,
    );
  }

  // TOOLTIP DINÀMIC: Usat per l'agulla central del dit
  void _paintDynamicTooltipBox(
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
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final double w = textPainter.width + 16;
    final double h = textPainter.height + 12;
    double rectX = (x - w / 2).clamp(4.0, size.width - w - 4.0);
    double rectY = 4.0;

    final rect = Rect.fromLTWH(rectX, rectY, w, h);
    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRect(rect, bg);
    textPainter.paint(canvas, Offset(rectX + 8, rectY + 6));
  }

  // TOOLTIP FIXAT EXTREMS: Rectangles quadrats clàssics immutables
  void _paintTooltipBoxFixed(
    Canvas canvas,
    Size size,
    String text,
    Color bgColor, {
    required bool forceLeft,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double w = textPainter.width + 14;
    final double h = textPainter.height + 10;

    // Posició clada rígidament horitzontal: costat esquerre o dret completament
    double rectX = forceLeft ? 4.0 : (size.width - w - 4.0);
    double rectY = 4.0;

    final rect = Rect.fromLTWH(rectX, rectY, w, h);
    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRect(rect, bg);
    textPainter.paint(canvas, Offset(rectX + 7, rectY + 5));
  }

  @override
  bool shouldRepaint(covariant SelectionPainter old) => true;
}
