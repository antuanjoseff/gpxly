import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/ui/bottom_bar/app_action_button.dart';

import 'tabs/gps_settings_tab.dart';
import 'tabs/gpx_settings_tab.dart';
import 'tabs/track_settings_tab.dart';

class GpsSettingsScreen extends ConsumerStatefulWidget {
  const GpsSettingsScreen({super.key});

  @override
  ConsumerState<GpsSettingsScreen> createState() => _GpsSettingsScreenState();
}

class _GpsSettingsScreenState extends ConsumerState<GpsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _hasPendingChanges = false;

  void markPending() {
    setState(() => _hasPendingChanges = true);
  }

  void clearPending() {
    setState(() => _hasPendingChanges = false);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_hasPendingChanges) {
          Navigator.of(context).pop();
          return;
        }

        final apply = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Canvis pendents"),
            content: const Text(
              "Has fet canvis que no has aplicat. Vols aplicar-los abans de tornar al mapa?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Descarta"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Aplica"),
              ),
            ],
          ),
        );

        if (apply == true) {
          // Cada pestanya aplica els seus settings
          GpsSettingsTab.apply(ref);
          GpxSettingsTab.apply(ref);
          TrackSettingsTab.apply(ref);

          clearPending();
          Navigator.of(context).pop();
        } else if (apply == false) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Configuració'),
          toolbarHeight:
              80, // 👈 Augmentem l'alçada del títol perquè sigui més ample
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.white,
              child: TabBar(
                controller: _tabController,
                // Icones i text no seleccionats: Molt més transparents (opacitat baixa)
                unselectedLabelColor: AppColors.primary.withAlpha(80),
                labelColor: AppColors.primary,

                // Estils de text per diferenciar per pes i mida
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),

                // INDICADOR: Ocupa tot l'ample de la seva secció (1/3 de la pantalla cadascun)
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4, color: AppColors.secondary),
                  insets: EdgeInsets
                      .zero, // 👈 Zero insets perquè arribi fins als extrems
                ),

                // Forçar que les pestanyes ocupin tot l'espai horitzontal disponible
                indicatorSize: TabBarIndicatorSize.tab,

                tabs: const [
                  Tab(icon: Icon(Icons.gps_fixed, size: 22), text: "GPS"),
                  Tab(icon: Icon(Icons.map, size: 22), text: "GPX"),
                  Tab(icon: Icon(Icons.timeline, size: 22), text: "Track"),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(
          controller: _tabController,
          children: [
            GpsSettingsTab(onPending: markPending, onApplied: clearPending),
            GpxSettingsTab(onPending: markPending, onApplied: clearPending),
            TrackSettingsTab(onPending: markPending, onApplied: clearPending),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: const Color(0xFFF5F5F7),
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppActionButton(
                    flex: 1,
                    onPressed: _hasPendingChanges
                        ? () {
                            GpsSettingsTab.apply(ref);
                            GpxSettingsTab.apply(ref);
                            TrackSettingsTab.apply(ref);

                            clearPending();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Configuració aplicada!"),
                              ),
                            );
                          }
                        : null,
                    color: _hasPendingChanges
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.35),
                    child: const Text(
                      "APLICA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
