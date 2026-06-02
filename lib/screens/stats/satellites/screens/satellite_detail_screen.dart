// lib/stats/satellites/screens/satellite_detail_screen.dart (PARTE 1)
import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/services/native_gps_channel.dart';
import 'constellation_page.dart';
import '../painters/skyplot_painter.dart';

class SatelliteDetailScreen extends StatefulWidget {
  const SatelliteDetailScreen({super.key});

  @override
  State<SatelliteDetailScreen> createState() => _SatelliteDetailScreenState();
}

class _SatelliteDetailScreenState extends State<SatelliteDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, String> _parseConstellation(int type, int svid) {
    switch (type) {
      case 1:
        return {'name': 'GPS', 'code': 'G$svid'};
      case 3:
        return {'name': 'GLONASS', 'code': 'R$svid'};
      case 6:
        return {'name': 'GALILEO', 'code': 'E$svid'};
      case 5:
        return {'name': 'BEIDOU', 'code': 'B$svid'};
      default:
        return {'name': 'UNKNOWN', 'code': 'U$svid'};
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Resum de Xarxes';
    if (_currentPage == 1) title = 'Intensitat de Senyal';
    if (_currentPage == 2) title = 'Skyplot Satèl·lits';

    return StreamBuilder<List<dynamic>>(
      stream: NativeGpsChannel.satelliteStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final satellites = snapshot.data ?? [];
        if (satellites.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(
              child: Text(
                'Buscant satèl·lits... Assegura\'t de tenir el GPS actiu exterior.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // 🚀 SOLUCIÓ: Reinicialitzem el controlador amb la pàgina actual desada a l'estat
        // Així, quan el StreamBuilder es reconstrueixi, no perdràs la teva posició de Swipe.
        final localController = PageController(initialPage: _currentPage);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppColors.primary,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 8,
                      width: _currentPage == index ? 16 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withAlpha(100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: PageView(
            controller: localController, // 👈 Passem el controlador fixat
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              ConstellationPage(
                satellites: satellites,
                parseFn: _parseConstellation,
              ),
              _buildGarminBarChartPage(satellites),
              _buildSkyplotPage(satellites),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGarminBarChartPage(List<dynamic> satellites) {
    final displaySats = satellites.take(15).toList();
    return Padding(
      padding: const EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 24.0,
        top: 24.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displaySats.map((sat) {
          final map = Map<String, dynamic>.from(sat);
          final cn0 = (map['cn0'] as num).toDouble();
          final usedInFix = map['usedInFix'] as bool;
          final parsed = _parseConstellation(
            map['constellation'] as int,
            map['svid'] as int,
          );

          final double heightFactor = (cn0 / 50.0).clamp(0.05, 1.0);
          final barColor = usedInFix
              ? Colors.green
              : Colors.grey.withAlpha(140);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  cn0.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  parsed['code']!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkyplotPage(List<dynamic> satellites) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: CustomPaint(
            painter: SkyplotPainter(
              satellites: satellites,
              parseFn: _parseConstellation,
            ),
          ),
        ),
      ),
    );
  }
}
