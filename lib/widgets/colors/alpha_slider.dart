import 'package:flutter/material.dart';
import 'package:senda/widgets/colors/checkerboard_painter.dart';

class AlphaSlider extends StatelessWidget {
  const AlphaSlider({
    super.key,
    required this.color,
    required this.alpha,
    required this.onChanged,
  });

  final Color color;
  final double alpha;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 14,
          thumbShape: const _AlphaThumbShape(radius: 12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          trackShape: _AlphaTrackShape(color: color),
        ),
        child: Slider(
          min: 0,
          max: 1,
          value: alpha.clamp(0, 1),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AlphaTrackShape extends SliderTrackShape {
  const _AlphaTrackShape({required this.color});

  final Color color;

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

    final canvas = context.canvas;

    canvas.save();

    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
    );

    CheckerboardPainter().paint(canvas, rect.size);

    canvas.restore();

    // Gradient transparent -> color
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withAlpha(0), color.withAlpha(255)],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );

    canvas.drawRRect(rrect, gradientPaint);
  }
}

class _AlphaThumbShape extends SliderComponentShape {
  const _AlphaThumbShape({required this.radius});

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

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fill);

    final border = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, border);
  }
}
