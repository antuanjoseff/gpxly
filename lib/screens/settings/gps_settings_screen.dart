import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/theme/app_colors.dart';

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
          title: const Text('Configuració'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.white, // ✔ fons blanc
              child: TabBar(
                controller: _tabController,
                unselectedLabelColor:
                    AppColors.primary, // ✔ icones/text no seleccionats
                labelColor: AppColors.primary, // ✔ icones/text seleccionats
                indicatorColor: AppColors.secondary, // ✔ línia inferior del tab
                tabs: const [
                  Tab(icon: Icon(Icons.gps_fixed), text: "GPS"),
                  Tab(icon: Icon(Icons.map), text: "GPX"),
                  Tab(icon: Icon(Icons.timeline), text: "Track"),
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
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _hasPendingChanges
                ? () {
                    GpsSettingsTab.apply(ref);
                    GpxSettingsTab.apply(ref);
                    TrackSettingsTab.apply(ref);

                    clearPending();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Configuració aplicada!")),
                    );
                  }
                : null, // desactivat si no hi ha canvis
            child: const Text("APLICA"),
          ),
        ),
      ),
    );
  }
}
