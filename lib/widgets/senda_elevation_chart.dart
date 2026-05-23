import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class SendaElevationChart extends StatefulWidget {
  final Track? real;
  final Track? imported;
  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;
  final List<int>? recordedWaypointIndices;
  final List<int>? importedWaypointIndices;
  final Function(int)? onNeedleMove;
  final Function(int, int)? onRangeSelected;
  final VoidCallback onClearSelection;

  const SendaElevationChart({
    super.key,
    this.real,
    this.imported,
    this.selectedIndexStart,
    this.selectedIndexEnd,
    this.selectedIndexGraph,
    this.recordedWaypointIndices,
    this.importedWaypointIndices,
    this.onNeedleMove,
    this.onRangeSelected,
    required this.onClearSelection,
  });

  @override
  State<SendaElevationChart> createState() => _SendaElevationChartState();
}

class _SendaElevationChartState extends State<SendaElevationChart> {
  final ValueNotifier<double?> needleXNotifier = ValueNotifier<double?>(null);
  int _draggingNeedle = 0; // 1: start, 2: end, 3: agulla

  @override
  Widget build(BuildContext context) {
    final primary = widget.real ?? widget.imported;
    if (primary == null || primary.distances.isEmpty)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double mapX(double d) => (d / primary.distances.last) * (w - 48) + 24;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) {
              final x = details.localPosition.dx;
              final sX = widget.selectedIndexStart != null
                  ? mapX(primary.distances[widget.selectedIndexStart!])
                  : -100.0;
              final eX = widget.selectedIndexEnd != null
                  ? mapX(primary.distances[widget.selectedIndexEnd!])
                  : -100.0;
              if ((x - sX).abs() < 30)
                _draggingNeedle = 1;
              else if ((x - eX).abs() < 30)
                _draggingNeedle = 2;
              else {
                _draggingNeedle = 3;
                _update(x, w, primary);
              }
            },
            onPanUpdate: (details) =>
                _update(details.localPosition.dx, w, primary),
            onPanEnd: (_) => _draggingNeedle = 0,
            onTapUp: (d) {
              if (_draggingNeedle == 0) widget.onClearSelection();
            },
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(w, h),
                  painter: _StaticProfilePainter(
                    real: widget.real,
                    imported: widget.imported,
                    startIndex: widget.selectedIndexStart,
                    endIndex: widget.selectedIndexEnd,
                  ),
                ),
                ValueListenableBuilder<double?>(
                  valueListenable: needleXNotifier,
                  builder: (context, val, _) => CustomPaint(
                    size: Size(w, h),
                    painter: _InteractivePainter(
                      needleX: val,
                      real: widget.real,
                      imported: widget.imported,
                      recordedWaypointIndices: widget.recordedWaypointIndices,
                      importedWaypointIndices: widget.importedWaypointIndices,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _update(double x, double width, Track primary) {
    final usableW = width - 48;
    final int idx =
        (((x - 24).clamp(0.0, usableW)) /
                usableW *
                (primary.distances.length - 1))
            .round();
    if (_draggingNeedle == 1 || _draggingNeedle == 2) {
      int s = _draggingNeedle == 1 ? idx : (widget.selectedIndexStart ?? idx);
      int e = _draggingNeedle == 2 ? idx : (widget.selectedIndexEnd ?? idx);
      widget.onRangeSelected?.call(s < e ? s : e, s < e ? e : s); // INVERSIÓ
    } else {
      widget.onNeedleMove?.call(idx);
      needleXNotifier.value = x;
    }
  }
}

class _Metrics {
  final double maxDist, minAlt, maxAlt, yRange, usableW, chartH, topRes, xAxisY;
  _Metrics({
    required this.maxDist,
    required this.minAlt,
    required this.maxAlt,
    required this.yRange,
    required this.usableW,
    required this.chartH,
    required this.topRes,
    required this.xAxisY,
  });
}

_Metrics _getMetrics(Size size, Track? r, Track? i) {
  final all = [if (r != null) ...r.altitudes, if (i != null) ...i.altitudes];
  final minA = all.isEmpty ? 0.0 : all.reduce((a, b) => a < b ? a : b);
  final maxA = all.isEmpty ? 100.0 : all.reduce((a, b) => a > b ? a : b);
  final diff = (maxA - minA).abs() < 10 ? 50.0 : (maxA - minA).abs();
  return _Metrics(
    maxDist: [
      r?.distances.last ?? 0.0,
      i?.distances.last ?? 0.0,
    ].reduce((a, b) => a > b ? a : b),
    minAlt: minA - (diff * 0.1),
    maxAlt: maxA + (diff * 0.1),
    yRange: (maxA + diff * 0.1) - (minA - diff * 0.1),
    usableW: size.width - 48,
    chartH: size.height - 100,
    topRes: 60,
    xAxisY: size.height - 40,
  );
}

class _StaticProfilePainter extends CustomPainter {
  final Track? real;
  final Track? imported;
  final int? startIndex, endIndex;
  _StaticProfilePainter({
    this.real,
    this.imported,
    this.startIndex,
    this.endIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = _getMetrics(size, real, imported);
    final pGrid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(24, m.topRes),
      Offset(size.width - 24, m.topRes),
      pGrid,
    ); // Línia Max
    canvas.drawLine(
      Offset(24, m.xAxisY),
      Offset(size.width - 24, m.xAxisY),
      pGrid,
    ); // Línia Min

    if (startIndex != null && endIndex != null) {
      final t = real ?? imported!;
      final sX = (t.distances[startIndex!] / m.maxDist) * m.usableW + 24;
      final eX = (t.distances[endIndex!] / m.maxDist) * m.usableW + 24;
      canvas.drawRect(
        Rect.fromLTRB(sX, m.topRes, eX, m.xAxisY),
        Paint()..color = Colors.orange.withAlpha(30),
      );
    }
    if (imported != null)
      _drawPath(
        canvas,
        imported!,
        m,
        AppColors.trackGreen.withAlpha(100),
        true,
      );
    if (real != null) _drawPath(canvas, real!, m, AppColors.redAlert, false);
  }

  void _drawPath(Canvas canvas, Track t, _Metrics m, Color c, bool isImp) {
    final path = Path();
    for (int i = 0; i < t.distances.length; i++) {
      final x = (t.distances[i] / m.maxDist) * m.usableW + 24;
      final y = m.xAxisY - ((t.altitudes[i] - m.minAlt) / m.yRange * m.chartH);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final area = Path.from(path)
      ..lineTo((t.distances.last / m.maxDist) * m.usableW + 24, m.xAxisY)
      ..lineTo((t.distances.first / m.maxDist) * m.usableW + 24, m.xAxisY)
      ..close();
    canvas.drawPath(area, Paint()..color = c.withAlpha(20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- BLOC 3: PAINTER INTERACTIU (Agulles, Waypoints i Tooltips) ---
class _InteractivePainter extends CustomPainter {
  final double? needleX;
  final Track? real;
  final Track? imported;
  final List<int>? recordedWaypointIndices;
  final List<int>? importedWaypointIndices;

  _InteractivePainter({
    this.needleX,
    this.real,
    this.imported,
    this.recordedWaypointIndices,
    this.importedWaypointIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculem mètriques per saber on dibuixar
    final m = _getMetrics(size, real, imported);

    // 1. Dibuixar Waypoints a la base (xAxisY)
    _drawWp(canvas, m, real, recordedWaypointIndices, AppColors.redAlert);
    _drawWp(canvas, m, imported, importedWaypointIndices, AppColors.trackGreen);

    // 2. Dibuixar Agulla i Tooltip si l'usuari toca el gràfic
    if (needleX != null) {
      final x = needleX!.clamp(24.0, size.width - 24.0);
      final dist = ((x - 24) / m.usableW) * m.maxDist;

      // Tooltip flotant superior
      final String txt = "${(dist / 1000).toStringAsFixed(2)} km";
      final tp = TextPainter(
        text: TextSpan(
          text: txt,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rect = Rect.fromCenter(
        center: Offset(x, 30),
        width: tp.width + 20,
        height: 26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = AppColors.primary,
      );
      tp.paint(canvas, Offset(rect.left + 10, rect.top + 5));

      // Línia vertical de l'agulla
      canvas.drawLine(
        Offset(x, m.topRes - 10),
        Offset(x, m.xAxisY + 10),
        Paint()..color = Colors.black26,
      );
    }
  }

  void _drawWp(Canvas canvas, _Metrics m, Track? t, List<int>? idxs, Color c) {
    if (t == null || idxs == null) return;
    for (var i in idxs) {
      if (i >= t.distances.length) continue;
      final x = (t.distances[i] / m.maxDist) * m.usableW + 24;
      canvas.drawCircle(Offset(x, m.xAxisY - 4), 4, Paint()..color = c);
      canvas.drawCircle(
        Offset(x, m.xAxisY - 4),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InteractivePainter old) =>
      old.needleX != needleX;
}
