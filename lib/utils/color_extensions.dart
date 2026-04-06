import 'package:flutter/material.dart';

extension ColorToMapLibre on Color {
  String toMapLibreColor() {
    return '#${toARGB32().toRadixString(16).substring(2)}';
  }
}
