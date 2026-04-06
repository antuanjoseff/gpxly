import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class GpsSettingsTab extends ConsumerStatefulWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const GpsSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

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
      backgroundColor: AppColors.white,
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
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada $_seconds segons",
              style: TextStyle(
                fontSize: 16,
                color: _useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
                inactiveTrackColor: colors.onSurface.withAlpha(40),
                trackHeight: _useTime ? 6 : 3,
                thumbColor: _useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
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
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Cada ${_meters.toInt()} metres",
              style: TextStyle(
                fontSize: 16,
                color: !_useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
              ),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: !_useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
                inactiveTrackColor: colors.onSurface.withAlpha(40),
                trackHeight: !_useTime ? 6 : 3,
                thumbColor: !_useTime
                    ? AppColors.primary
                    : colors.onSurface.withAlpha(40),
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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "${_accuracy.toInt()} metres",
              style: TextStyle(fontSize: 16, color: colors.onSurface),
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: colors.onSurface.withAlpha(51),
                thumbColor: AppColors.primary,
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
    );
  }
}
