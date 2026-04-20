import 'package:flutter/material.dart';

class StopFollowingIconStack extends StatelessWidget {
  final double size;
  final Color navColor;
  final Color crossColor;

  const StopFollowingIconStack({
    super.key,
    this.size = 28,
    this.navColor = Colors.white,
    this.crossColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.navigation, size: size, color: navColor),
        Icon(Icons.close, size: size * 0.55, color: crossColor),
      ],
    );
  }
}

class StopFollowingIconCircle extends StatelessWidget {
  final double size;
  final Color circleColor;
  final Color iconColor;

  const StopFollowingIconCircle({
    super.key,
    this.size = 22,
    this.circleColor = Colors.red,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
      padding: EdgeInsets.all(size * 0.27),
      child: Icon(Icons.navigation, size: size, color: iconColor),
    );
  }
}
