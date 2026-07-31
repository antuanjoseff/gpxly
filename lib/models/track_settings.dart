import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';

class TrackSettings {
  final Color color;
  final double width;

  // 👈 Modificat: ara agafa el verd fosc d'AppColors per defecte
  const TrackSettings({
    this.color = AppColors.recordedTrackColor,
    this.width = 4,
  });

  TrackSettings copyWith({Color? color, double? width}) {
    return TrackSettings(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}
