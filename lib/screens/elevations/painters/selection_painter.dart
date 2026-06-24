// lib/screens/elevations/painters/selection_painter.dart (BLOC 1 DE 2 CORREGIT)
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

  final double topReserved;
  final double bottomReserved;
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
    this.recordedWaypointGlobalDists,
    this.importedWaypointGlobalDists,
  });

  @override
  @override
  void paint(Canvas canvas, Size size) {
    if (distances.isEmpty || altitudes.isEmpty) return;

    final chartHeight = size.height - bottomReserved - topReserved;
    final xAxisY = topReserved + chartHeight;

    final minAlt = altitudes.reduce((a, b) => a < b ? a : b);
    final maxAlt = altitudes.reduce((a, b) => a > b ? a : b);
    final diff = (maxAlt - minAlt).abs();

    // 🎯 RECTIFICACIÓ COMPLETA DEL RESPALDO (Sincronitzat al 100% amb el gràfic de fons)
    final double paddingRange = diff < 10 ? 10 : diff;
    final minY = minAlt - (paddingRange * 0.10);
    final maxY = maxAlt + (paddingRange * 0.15);
    final yRange = maxY - minY;

    final usableWidth = size.width;
    final maxDist = distances.last;

    double mapX(double dist) {
      if (maxDist == 0) return 0;
      return (dist / maxDist) * usableWidth;
    }

    // Ajuda matemàtica local per saber exactament la Y en píxels d'un punt muntanyós
    double calculatePointY(int idx) {
      if (idx < 0 || idx >= altitudes.length || yRange == 0) return topReserved;
      final double rel = (altitudes[idx] - minY) / yRange;
      return topReserved + (chartHeight - (rel * chartHeight));
    }

    // WAYPOINTS GRAVATS
    if (recordedWaypointGlobalDists != null &&
        recordedWaypointGlobalDists!.isNotEmpty) {
      final recWpPaint = Paint()
        ..color = recordedWaypointColor
        ..style = PaintingStyle.fill;
      for (final d in recordedWaypointGlobalDists!) {
        canvas.drawCircle(Offset(mapX(d), xAxisY), 4, recWpPaint);
      }
    }

    // WAYPOINTS IMPORTATS
    if (importedWaypointGlobalDists != null &&
        importedWaypointGlobalDists!.isNotEmpty) {
      final impWpPaint = Paint()
        ..color = importedWaypointColor
        ..style = PaintingStyle.fill;
      for (final d in importedWaypointGlobalDists!) {
        canvas.drawCircle(Offset(mapX(d), xAxisY), 4, impWpPaint);
      }
    }

    final int? sIndex = startIndex;
    final int? eIndex = endIndex;
    final double? sX = startX;
    final double? eX = endX;

    bool isCrossed = false;
    if (sX != null && eX != null) {
      isCrossed = eX < sX;
    }

    // 1. DIBUIX DE L'AGULLA DE L'ESQUERRA (Verd)
    if (sX != null && sIndex != null && eX != null && eIndex != null) {
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

      final distKm = distances[leftIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[leftIndex].toStringAsFixed(0)} m",
        sliderStartNeedleColor.withAlpha(230),
        forceLeft: true,
        targetY:
            topReserved, // 🚀 Clavat horitzontalment a dalt de tot de la zona del gràfic
      );
    } else if (sX != null && sIndex != null) {
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
        targetY: topReserved, // 🚀 Clavat horitzontalment a dalt de tot
      );
    }

    // 2. DIBUIX DE L'AGULLA DE LA DRETA (Vermell)
    if (sX != null && sIndex != null && eX != null && eIndex != null) {
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

      final distKm = distances[rightIndex] / 1000.0;
      _paintTooltipBoxFixed(
        canvas,
        size,
        "${distKm.toStringAsFixed(2)} km | ${altitudes[rightIndex].toStringAsFixed(0)} m",
        sliderEndNeedleColor.withAlpha(230),
        forceLeft: false,
        targetY: topReserved, // 🚀 Clavat horitzontalment a dalt de tot
      );
    } else if (eX != null && eIndex != null) {
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
        targetY: topReserved, // 🚀 Clavat horitzontalment a dalt de tot
      );
    }

    // 3. L'agulla central del dit (Mira taronja continuat)
    if (graphX != null && graphIndex != null) {
      // 🚀 Modificació per al dit: Enviem la Y actual del punt que l'usuari està pitjant
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
        topReserved,
      );
    }
  }

  // lib/screens/elevations/painters/selection_painter.dart (BLOC 2 DE 2 CORREGIT)

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

    // 🛡️ CÀLCUL DAMUNT LA SILUETA: Amb el topReserved a 10, la rodona s'acobla perfectament al relleu
    final double rel = (altitudes[index] - minY) / yRange;
    final double dy = topReserved + (chartHeight - (rel * chartHeight));

    // 🛡️ FI DE L'AGULLA AL TERRA: Definim el límit de baix en 'xAxisY' exactament.
    // Així la línia vertical s'atura just a sobre dels quilòmetres, sense foradar el fons.
    final double absoluteBottom = xAxisY;

    final linePaint = Paint()
      ..color = color.withAlpha(150)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, absoluteBottom), Offset(x, dy), linePaint);

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
    double
    targetY, // 🎯 1. Afegim el sisè paràmetre aquí (la coordenada Y dinàmica de la línia)
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

    // 🎯 2. Ara sí: enviem els 6 arguments complets cap a la bafarada del dit
    _paintDynamicTooltipBox(
      canvas,
      size,
      x,
      "${distKm.toStringAsFixed(2)} km  |  ${altitudes[index].toStringAsFixed(0)} m",
      tooltipColor,
      targetY, // 👈 Passem el sisè argument per clavar el tooltip a la muntanya
    );
  }

  // 🎯 Tooltip del dit alineat al sostre útil de línies
  // 🎯 Tooltip flotant mòbil per al dit (CORREGIT)
  void _paintDynamicTooltipBox(
    Canvas canvas,
    Size size,
    double x,
    String text,
    Color bgColor,
    double
    targetY, // 👈 CRÍTIC: Afegim la Y real del punt on l'usuari té el dit
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

    // 🚀 LA COORDENADA FIXA ÉS HISTÒRIA:
    // Col·loquem el tooltip exactament 12 píxels per sobre del relleu real de la línia
    double rectY = targetY - h - 12.0;
    if (rectY < 4.0)
      rectY = 4.0; // Seguretat per si de cas un cim toqués el sostre

    final rect = Rect.fromLTWH(rectX, rectY, w, h);
    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(rect, bg);
    textPainter.paint(canvas, Offset(rectX + 8, rectY + 6));
  }

  // 🎯 Tooltips fixes laterals (Clavats al sostre real absolut de la pantalla)
  void _paintTooltipBoxFixed(
    Canvas canvas,
    Size size,
    String text,
    Color bgColor, {
    required bool forceLeft,
    required double
    targetY, // El mantenim a la capçalera per no trencar les crides
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

    double rectX = forceLeft ? 4.0 : (size.width - w - 4.0);

    // 🚀 FIXACIÓ ABSOLUTA AL SOSTRE:
    // Forcem que la Y de la bafarada sigui sempre de 4 píxels respecte al límit superior del giny.
    // D'aquesta manera queda independent de si el gràfic canvia de mida o té més o menys marge.
    double rectY = 4.0;

    final rect = Rect.fromLTWH(rectX, rectY, w, h);
    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRect(rect, bg);
    textPainter.paint(canvas, Offset(rectX + 7, rectY + 5));
  }

  bool _tooltipsOverlap(double x1, double x2, double width) {
    return (x1 - x2).abs() < width;
  }

  @override
  bool shouldRepaint(covariant SelectionPainter old) => true;
}
