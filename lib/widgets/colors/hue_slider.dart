import 'package:flutter/material.dart';

class HueSlider extends StatelessWidget {
  const HueSlider({super.key, required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 14,
          thumbShape: const _ColorThumbShape(radius: 12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          trackShape: const _GradientTrackShape(),
        ),
        child: Slider(
          min: 0,
          max: 360,
          value: hue.clamp(0, 360),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GradientTrackShape extends SliderTrackShape {
  const _GradientTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;

    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    Offset? secondaryOffset,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.red,
          Colors.yellow,
          Colors.green,
          Colors.cyan,
          Colors.blue,
          Colors.purple,
          Colors.red,
        ],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );

    context.canvas.drawRRect(rrect, paint);
  }
}

class _ColorThumbShape extends SliderComponentShape {
  const _ColorThumbShape({required this.radius});

  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    final border = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, border);
  }
}
