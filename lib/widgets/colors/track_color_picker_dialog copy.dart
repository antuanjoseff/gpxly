import 'package:flutter/material.dart';
import 'package:strack_rec/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();

    // 2. Creem l'HSV netejant l'opacitat (forçant alpha a 1.0) perquè no bloquegi els càlculs,
    // i ens assegurem que la saturació i el valor no estiguin a 0 (per si el color era negre o blanc)
    final tempHsv = HSVColor.fromColor(widget.initialColor);

    _hsv = HSVColor.fromAHSV(
      1.0,
      tempHsv.hue,
      tempHsv.saturation == 0 ? 1.0 : tempHsv.saturation,
      tempHsv.value == 0 ? 0.8 : tempHsv.value, // 0.8 evita el negre absolut
    );
  }

  // Genera el color final fusionant el color triat amb l'opacitat actual de l'Slider
  Color get _currentColor {
    return _hsv.toColor();
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

              // Cercle de previsualització
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

              // Selector de Tonalitat (Hue)
              HueSlider(
                hue: _hsv.hue,
                onChanged: (value) {
                  setState(() {
                    // Si el color d'origen és massa fosc o apagat (com el deepGreen),
                    // forcem una saturació i brillantor mínimes (ex: 0.9) perquè l'usuari
                    // vegi clarament el color brillant que està escollint en el cercle.
                    final double activeSaturation = _hsv.saturation < 0.6
                        ? 0.9
                        : _hsv.saturation;
                    final double activeValue = _hsv.value < 0.6
                        ? 0.9
                        : _hsv.value;

                    _hsv = HSVColor.fromAHSV(
                      1.0,
                      value,
                      activeSaturation,
                      activeValue,
                    );
                  });
                },
              ),

              const SizedBox(height: 28),

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
