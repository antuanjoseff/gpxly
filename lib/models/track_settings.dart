import 'package:flutter/material.dart';

class TrackSettings {
  final Color color;
  final double width;

  const TrackSettings({this.color = Colors.blue, this.width = 4});

  TrackSettings copyWith({Color? color, double? width}) {
    return TrackSettings(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }
}
