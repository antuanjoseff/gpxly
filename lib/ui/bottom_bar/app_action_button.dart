import 'package:flutter/material.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'pressable_scale.dart';

class AppActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;
  final Widget child;
  final int flex;

  const AppActionButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.child,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: PressableScale(
        onTap: onPressed,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
