import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/ui/app_styles.dart';

class GpsSettingsTab extends ConsumerStatefulWidget {
  final VoidCallback onPending;

  const GpsSettingsTab({super.key, required this.onPending});

  static void apply(WidgetRef ref) {
    final notifier = ref.read(gpsSettingsProvider.notifier);
    final s = ref.read(gpsSettingsProvider);

    notifier.setUseTime(s.useTime);
    notifier.setSeconds(s.seconds);
    notifier.setMeters(s.meters);
    notifier.setAccuracy(s.accuracy);
  }

  @override
  ConsumerState<GpsSettingsTab> createState() => _GpsSettingsTabState();
}

class _GpsSettingsTabState extends ConsumerState<GpsSettingsTab> {
  late bool _useTime;
  late int _seconds;
  late double _meters;
  late double _accuracy;

  bool _pending = false;

  void _markPending() {
    setState(() => _pending = true);
    widget.onPending();
  }

  @override
  void initState() {
    super.initState();
    final gps = ref.read(gpsSettingsProvider);

    _useTime = gps.useTime;
    _seconds = gps.seconds;
    _meters = gps.meters;
    _accuracy = gps.accuracy;
  }

  void _applySettings() {
    final notifier = ref.read(gpsSettingsProvider.notifier);

    notifier.setUseTime(_useTime);
    notifier.setSeconds(_seconds);
    notifier.setMeters(_meters);
    notifier.setAccuracy(_accuracy);

    setState(() => _pending = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Configuració GPS aplicada!")));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // SLIDER TEMPS
            // -------------------------
            Text(
              "Gravació per temps",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada $_seconds segons",
              style: TextStyle(
                fontSize: 16,
                color: _useTime
                    ? colors.onSurface
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.3),
                inactiveTrackColor: colors.onSurface.withOpacity(0.2),
                trackHeight: _useTime ? 6 : 3,
                thumbColor: _useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.4),
              ),
              child: Slider(
                value: _seconds.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: _seconds.toString(),
                onChanged: (val) {
                  setState(() {
                    _seconds = val.round();
                    _useTime = true;
                  });
                  _markPending();
                },
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------
            // SLIDER METRES
            // -------------------------
            Text(
              "Gravació per distància",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: !_useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada ${_meters.toInt()} metres",
              style: TextStyle(
                fontSize: 16,
                color: !_useTime
                    ? colors.onSurface
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: !_useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.3),
                inactiveTrackColor: colors.onSurface.withOpacity(0.2),
                trackHeight: !_useTime ? 6 : 3,
                thumbColor: !_useTime
                    ? colors.primary
                    : colors.onSurface.withOpacity(0.4),
              ),
              child: Slider(
                value: _meters,
                min: 1,
                max: 100,
                divisions: 99,
                label: _meters.toInt().toString(),
                onChanged: (val) {
                  setState(() {
                    _meters = val.roundToDouble();
                    _useTime = false;
                  });
                  _markPending();
                },
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------
            // SLIDER ACCURACY
            // -------------------------
            Text(
              "Accuracy màxima",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "${_accuracy.toInt()} metres",
              style: TextStyle(fontSize: 16, color: colors.onSurface),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colors.secondary,
                inactiveTrackColor: colors.onSurface.withOpacity(0.2),
                thumbColor: colors.secondary,
              ),
              child: Slider(
                value: _accuracy,
                min: 5,
                max: 100,
                divisions: 19,
                label: _accuracy.toInt().toString(),
                onChanged: (val) {
                  setState(() {
                    _accuracy = val;
                  });
                  _markPending();
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: AppButtons.active,
          onPressed: _applySettings,
          child: const Text("Apply"),
        ),
      ),
    );
  }
}
