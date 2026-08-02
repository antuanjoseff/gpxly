// lib/stats/satellites/screens/satellite_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/services/native_gps_channel.dart';
import '../painters/skyplot_painter.dart';

class SatelliteDetailScreen extends StatefulWidget {
  const SatelliteDetailScreen({super.key});

  @override
  State<SatelliteDetailScreen> createState() => _SatelliteDetailScreenState();
}

class _SatelliteDetailScreenState extends State<SatelliteDetailScreen> {
  final Map<int, bool> _enabledConstellations = {
    1: true, // GPS
    3: true, // GLONASS
    6: true, // GALILEO
    5: true, // BEIDOU
  };
  static const Map<int, Map<String, dynamic>> _constellationMeta = {
    1: {'name': 'GPS', 'codePrefix': 'G', 'flag': '🇺🇸', 'sortKey': 0},
    3: {'name': 'GLONASS', 'codePrefix': 'R', 'flag': '🇷🇺', 'sortKey': 1},
    6: {'name': 'GALILEO', 'codePrefix': 'E', 'flag': '🇪🇺', 'sortKey': 2},
    5: {'name': 'BEIDOU', 'codePrefix': 'B', 'flag': '🇨🇳', 'sortKey': 3},
  };
  bool _useFlags = true;

  Map<String, String> _parseConstellation(int type, int svid) {
    final info = _constellationMeta[type];
    if (info != null) {
      return {
        'name': info['name'] as String,
        'code': '${info['codePrefix'] as String}$svid',
      };
    }

    return {'name': 'UNKNOWN', 'code': 'U$svid'};
  }

  @override
  Widget build(BuildContext context) {
    final double radarSize = MediaQuery.of(context).size.width * 0.85;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.satelliteSkyplotTitle),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _useFlags ? t.satelliteFlagsMode : t.satelliteGeometryMode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 2),
                Transform.scale(
                  scale: 0.72,
                  child: Switch.adaptive(
                    value: _useFlags,
                    onChanged: (value) {
                      setState(() {
                        _useFlags = value;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<dynamic>>(
        stream: NativeGpsChannel.satelliteStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final satellites = snapshot.data ?? [];
          final filtered = satellites.where((sat) {
            final map = Map<String, dynamic>.from(sat);
            final type = map['constellation'] as int;
            return _enabledConstellations[type] ?? true;
          }).toList();

          if (satellites.isEmpty) {
            return Center(
              child: Text(
                t.satelliteSearching,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Filtros de conteo para la telemetría superior
          int usedCount = 0;
          for (var sat in satellites) {
            if (Map<String, dynamic>.from(sat)['usedInFix'] as bool) {
              usedCount++;
            }
          }

          final gpsCount = _satelliteCountForConstellation(satellites, 1);
          final glonassCount = _satelliteCountForConstellation(satellites, 3);
          final galileoCount = _satelliteCountForConstellation(satellites, 6);
          final beidouCount = _satelliteCountForConstellation(satellites, 5);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. FILA SUPERIOR: Telemetría a la izquierda y Leyenda fuera del gráfico a la derecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado izquierdo: Tu panel de telemetría original
                  _buildTelemetryPanel(satellites.length, usedCount),

                  // Lado derecho: La leyenda de formas geométricas alineada arriba
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(top: 4.0, right: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendRow(
                          t.satelliteConstellationGps,
                          1,
                          gpsCount,
                        ),
                        _buildLegendRow(
                          t.satelliteConstellationGlonass,
                          3,
                          glonassCount,
                        ),
                        _buildLegendRow(
                          t.satelliteConstellationGalileo,
                          6,
                          galileoCount,
                        ),
                        _buildLegendRow(
                          t.satelliteConstellationBeidou,
                          5,
                          beidouCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. RADAR CIRCULAR LIMPIO (SKYPLOT CENTRADO)
              Center(
                child: SizedBox(
                  width: radarSize,
                  height: radarSize,
                  child: CustomPaint(
                    painter: SkyplotPainter(
                      satellites: filtered,
                      parseFn: _parseConstellation,
                      useFlags: _useFlags,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. GRÁFICO DE BARRAS ESTILO GARMIN INFERIOR
              SizedBox(height: 140, child: _buildGarminBarChart(filtered)),
            ],
          );
        },
      ),
    );
  }

  // Widget auxiliar para pintar cada fila de la leyenda de constelaciones
  Widget _buildLegendRow(String label, int type, int count) {
    final enabled = _enabledConstellations[type] ?? true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _enabledConstellations[type] = !enabled;
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1.0 : 0.35,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✔️ Checkbox minimalista
                Icon(
                  enabled
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 14,
                  color: enabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),

                _useFlags
                    ? Text(
                        _constellationFlag(type),
                        style: const TextStyle(fontSize: 12),
                      )
                    : CustomPaint(
                        size: const Size(12, 12),
                        painter: _LegendShapePainter(constellationType: type),
                      ),
                const SizedBox(width: 8),

                // 🏷️ Nom de la constel·lació
                Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryPanel(int totalInView, int totalInUse) {
    final t = AppLocalizations.of(context)!;
    final TextStyle labelStyle = TextStyle(
      color: Colors.blue.shade700,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t.satelliteUtcTime}: ${DateTime.now().toUtc().toString().split(' ').last.split('.').first}',
            style: labelStyle,
          ),
          Text(
            '${t.satelliteFixType}: ${totalInUse >= 4 ? t.satelliteFix3dRtk : t.satelliteNoFix}',
            style: labelStyle,
          ),
          Text(
            '${t.satelliteSatellitesInView}: $totalInView',
            style: labelStyle,
          ),
          Text('${t.satelliteSatellitesInUse}: $totalInUse', style: labelStyle),
        ],
      ),
    );
  }

  Widget _buildGarminBarChart(List<dynamic> satellites) {
    final sortedSats = List<dynamic>.from(satellites)
      ..sort((a, b) {
        final aMap = Map<String, dynamic>.from(a);
        final bMap = Map<String, dynamic>.from(b);
        final aType = aMap['constellation'] as int;
        final bType = bMap['constellation'] as int;
        final typeCompare = _constellationSortKey(
          aType,
        ).compareTo(_constellationSortKey(bType));
        if (typeCompare != 0) return typeCompare;
        final aCn0 = (aMap['cn0'] as num).toDouble();
        final bCn0 = (bMap['cn0'] as num).toDouble();
        return bCn0.compareTo(aCn0);
      });

    if (satellites.isEmpty) {
      final t = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          t.satelliteNoVisible,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: sortedSats.length,
        itemBuilder: (context, index) {
          final map = Map<String, dynamic>.from(sortedSats[index]);
          final constellationType = map['constellation'] as int;
          final cn0 = (map['cn0'] as num).toDouble();
          final parsed = _parseConstellation(
            constellationType,
            map['svid'] as int,
          );

          final double heightFactor = (cn0 / 50.0).clamp(0.05, 1.0);

          Color barColor = Colors.orange;
          if (cn0 >= 30.0) {
            barColor = Colors.green;
          } else if (cn0 >= 20.0) {
            barColor = Colors.amber;
          }

          return Container(
            width: 26,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  cn0.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 9,
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 80,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFactor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parsed['code']!,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _buildMarker(constellationType),
              ],
            ),
          );
        },
      ),
    );
  }

  int _constellationSortKey(int type) {
    return _constellationMeta[type]?['sortKey'] as int? ?? 99;
  }

  String _constellationFlag(int type) {
    return _constellationMeta[type]?['flag'] as String? ?? '🏳️';
  }

  int _satelliteCountForConstellation(List<dynamic> satellites, int type) {
    return satellites.where((sat) {
      final map = Map<String, dynamic>.from(sat);
      return map['constellation'] as int == type;
    }).length;
  }

  Widget _buildMarker(int type) {
    return _useFlags
        ? Text(_constellationFlag(type), style: const TextStyle(fontSize: 11))
        : CustomPaint(
            size: const Size(12, 12),
            painter: _LegendShapePainter(constellationType: type),
          );
  }
}

class _LegendShapePainter extends CustomPainter {
  final int constellationType;

  _LegendShapePainter({required this.constellationType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paintNode = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (constellationType == 1) {
      canvas.drawCircle(Offset.zero, 4.5, paintNode);
      canvas.drawCircle(Offset.zero, 4.5, paintStroke);
    } else if (constellationType == 3) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
        paintNode,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
        paintStroke,
      );
    } else if (constellationType == 6) {
      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(4.5, 3.5)
        ..lineTo(-4.5, 3.5)
        ..close();
      canvas.drawPath(path, paintNode);
      canvas.drawPath(path, paintStroke);
    } else {
      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(4.5, 0)
        ..lineTo(0, 5)
        ..lineTo(-4.5, 0)
        ..close();
      canvas.drawPath(path, paintNode);
      canvas.drawPath(path, paintStroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LegendShapePainter oldDelegate) => false;
}
