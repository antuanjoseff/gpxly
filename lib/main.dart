import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/screens/map_screen.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/theme/sendak_theme.dart';

void main() {
  runApp(const ProviderScope(child: GPXlyApp()));
}

class GPXlyApp extends StatelessWidget {
  const GPXlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPXly',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const MapScreen(),
    );
  }
}
