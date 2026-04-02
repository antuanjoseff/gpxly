import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_settings_provider.dart';

class GpsSettingsScreen extends ConsumerStatefulWidget {
  const GpsSettingsScreen({super.key});

  @override
  ConsumerState<GpsSettingsScreen> createState() => _GpsSettingsScreenState();
}

class _GpsSettingsScreenState extends ConsumerState<GpsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late bool _useTime;
  late int _seconds;
  late double _meters;
  late double _accuracy;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final gpsSettings = ref.read(gpsSettingsProvider);

    _useTime = gpsSettings.useTime;
    _seconds = gpsSettings.seconds;
    _meters = gpsSettings.meters;
    _accuracy = gpsSettings.accuracy;

    _tabController = TabController(length: 3, vsync: this);
  }

  void _applySettings() {
    final notifier = ref.read(gpsSettingsProvider.notifier);

    notifier.setUseTime(_useTime);
    notifier.setSeconds(_seconds);
    notifier.setMeters(_meters);
    notifier.setAccuracy(_accuracy);

    print(
      "[GPS] Settings applied: useTime=$_useTime, seconds=$_seconds, meters=$_meters, accuracy=$_accuracy",
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuració GPS aplicada!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuració GPS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: "Temps"),
            Tab(icon: Icon(Icons.straighten), text: "Metres"),
            Tab(icon: Icon(Icons.gps_fixed), text: "Accuracy"),
          ],
          indicator: BoxDecoration(
            color: Colors.blue.withValues(
              alpha: .15,
            ), // color de fons de la pestanya activa
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab, // ocupa tota la pestanya
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            // --- Pestanya Temps ---
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Icon(Icons.timer),
                  selected: _useTime,
                  onSelected: (val) {
                    setState(() {
                      _useTime = true;
                      _meters = 1; // metres mínim
                    });
                  },
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _seconds.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 60 - 1,
                  label: _seconds.toString(),
                  onChanged: (val) {
                    setState(() {
                      _seconds = val.round();
                      _meters = 1; // metres mínim
                    });
                  },
                ),
                const Icon(Icons.timer),
              ],
            ),

            // --- Pestanya Metres ---
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Icon(Icons.straighten),
                  selected: !_useTime,
                  onSelected: (val) {
                    setState(() {
                      _useTime = false;
                      _seconds = 1; // temps mínim
                    });
                  },
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _meters,
                  min: 1,
                  max: 100,
                  divisions: 100 - 1,
                  label: _meters.toInt().toString(),
                  onChanged: (val) {
                    setState(() {
                      _meters = val.roundToDouble();
                      _seconds = 1; // temps mínim
                    });
                  },
                ),
                const Icon(Icons.straighten),
              ],
            ),

            // --- Pestanya Accuracy ---
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Accuracy màxima (${_accuracy.toInt()} m)"),
                Slider(
                  value: _accuracy,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: _accuracy.toInt().toString(),
                  onChanged: (val) {
                    setState(() {
                      _accuracy = val;
                    });
                  },
                ),
                const Icon(Icons.gps_fixed),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _applySettings,
          child: const Text("Apply"),
        ),
      ),
    );
  }
}
