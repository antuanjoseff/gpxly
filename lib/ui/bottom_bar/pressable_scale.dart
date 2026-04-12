import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;
  final VoidCallback? onTap;

  const PressableScale({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 120),
    this.scale = 0.95,
    this.onTap,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _currentScale = 1.0;

  void _press(bool down) {
    setState(() => _currentScale = down ? widget.scale : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(true),
      onTapUp: (_) {
        _press(false);
        if (widget.onTap != null)
          widget.onTap!(); // 👈 EXECUTA L’ACCIÓ CORRECTAMENT
      },
      onTapCancel: () => _press(false),
      child: AnimatedScale(
        scale: _currentScale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
