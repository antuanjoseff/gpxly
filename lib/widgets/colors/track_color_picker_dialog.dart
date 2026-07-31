import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';

import 'alpha_slider.dart';
import 'hue_slider.dart';

Future<Color?> showTrackColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TrackColorPickerDialog(initialColor: initialColor),
  );
}

class _TrackColorPickerDialog extends StatefulWidget {
  const _TrackColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_TrackColorPickerDialog> createState() =>
      _TrackColorPickerDialogState();
}

class _TrackColorPickerDialogState extends State<_TrackColorPickerDialog> {
  late HSVColor _hsv;
  late double _alpha;

  @override
  void initState() {
    super.initState();

    _hsv = HSVColor.fromColor(widget.initialColor);
    _alpha = widget.initialColor.alpha / 255.0;
  }

  Color get _currentColor {
    return _hsv.toColor().withAlpha((_alpha * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.pickColor, style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 28),

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentColor,
                  border: Border.all(color: Colors.black12),
                ),
              ),

              const SizedBox(height: 32),

              HueSlider(
                hue: _hsv.hue,
                onChanged: (value) {
                  setState(() {
                    _hsv = HSVColor.fromAHSV(
                      1.0,
                      value,
                      _hsv.saturation,
                      _hsv.value,
                    );
                  });
                },
              ),

              const SizedBox(height: 28),

              AlphaSlider(
                color: _hsv.toColor(),
                alpha: _alpha,
                onChanged: (value) {
                  setState(() {
                    _alpha = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_currentColor);
                  },
                  child: const Text('Acceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
