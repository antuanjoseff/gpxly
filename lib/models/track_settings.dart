import 'package:flutter/material.dart';

class TrackSettings {
  final Color color;
  final double width;

  // 👈 Modificat: ara agafa el verd fosc d'AppColors per defecte
  const TrackSettings({required this.color, this.width = 4});

  TrackSettings copyWith({Color? color, double? width}) {
    return TrackSettings(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}
