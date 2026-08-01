import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<Color?> showTrackColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
}) {
  Color selectedColor = initialColor;

  return showDialog<Color>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: initialColor,
            onColorChanged: (color) {
              selectedColor = color;
            },
            // Opcional: Pots definir tu mateix la llista de colors exacte si vols,
            // però per defecte ja inclou la graella que es veu a la imatge.
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(selectedColor),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
