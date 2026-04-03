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
  late bool _hasPendingChanges = false;
  bool _pendingTime = false;
  bool _pendingMeters = false;
  bool _pendingAccuracy = false;

  void _markPending() {
    setState(() {
      _hasPendingChanges = true;
    });
  }

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

    setState(() {
      _hasPendingChanges = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuració GPS aplicada!')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Interceptem sempre el pop
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Ja ha fet pop, no fem res

        // Si no hi ha canvis pendents → sortir directament
        if (!_hasPendingChanges) {
          Navigator.of(context).pop();
          return;
        }

        // Mostrar diàleg
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
          _applySettings(); // Apliquem canvis
          Navigator.of(context).pop(); // Sortim
          return;
        }

        if (apply == false) {
          Navigator.of(context).pop(); // Sortim descartant
          return;
        }

        // Si tanca el diàleg sense triar → no sortir
      },
      child: Scaffold(
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
          child: Column(
            children: [
              Expanded(
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
                              _meters = 1;
                            });
                            _markPending();
                          },
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Text(
                              "Cada $_seconds segons",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _seconds.toDouble(),
                              min: 1,
                              max: 60,
                              divisions: 59,
                              label: _seconds.toString(),
                              onChanged: (val) {
                                setState(() {
                                  _seconds = val.round();
                                  _meters = 1;
                                  _pendingTime = true;
                                  _hasPendingChanges = true;
                                });

                                _markPending();
                              },
                            ),
                          ],
                        ),

                        const Icon(Icons.timer),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pendingTime
                                ? Colors.orange
                                : null,
                          ),
                          onPressed: () {
                            _applySettings();
                            setState(() => _pendingTime = false);
                          },
                          child: const Text("Aplica"),
                        ),
                      ],
                    ),
                    // --- Pestanya metres ---
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Icon(Icons.straighten),
                          selected: !_useTime,
                          onSelected: (val) {
                            setState(() {
                              _useTime = false;
                              _seconds = 1;
                            });
                            _markPending();
                          },
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Text(
                              "Cada ${_meters.toInt()} metres",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _meters,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              label: _meters.toInt().toString(),
                              onChanged: (val) {
                                setState(() {
                                  _meters = val.roundToDouble();
                                  _seconds = 1;
                                  _pendingMeters = true;
                                  _hasPendingChanges = true;
                                });

                                _markPending();
                              },
                            ),
                          ],
                        ),

                        const Icon(Icons.straighten),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pendingMeters
                                ? Colors.orange
                                : null,
                          ),
                          onPressed: () {
                            _applySettings();
                            setState(() => _pendingMeters = false);
                          },
                          child: const Text("Aplica"),
                        ),
                      ],
                    ),
                    // -- pestanya accuracy
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Accuracy màxima: ${_accuracy.toInt()} m",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: _accuracy,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: _accuracy.toInt().toString(),
                          onChanged: (val) {
                            setState(() {
                              _accuracy = val;
                              _pendingAccuracy = true;
                              _hasPendingChanges = true;
                            });

                            _markPending();
                          },
                        ),

                        const Icon(Icons.gps_fixed),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pendingAccuracy
                                ? Colors.orange
                                : null,
                          ),
                          onPressed: () {
                            _applySettings();
                            setState(() => _pendingAccuracy = false);
                          },
                          child: const Text("Aplica"),
                        ),
                      ],
                    ),
                  ],
                ),
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
      ),
    );
  }
}
