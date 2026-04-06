import 'package:flutter/material.dart';
import 'package:gpxly/theme/app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Fons general
  scaffoldBackgroundColor: AppColors.skyBlue,

  // ColorScheme amb els teus colors nous
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.skyBlue,
    brightness: Brightness.light,

    primary: AppColors.skyBlue,
    onPrimary: Colors.black,

    secondary: AppColors.mustardYellow,
    onSecondary: Colors.black,

    surface: Colors.white,
    onSurface: Colors.black,
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.deepGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      fontFamily: 'monospace',
      color: Colors.white,
    ),
  ),

  // Cards
  cardTheme: CardThemeData(
    color: AppColors.mustardYellow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.deepGreen.withOpacity(0.25)),
    ),
  ),

  // Botons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.mustardYellow,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  ),

  // Snackbars
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.mustardYellow,
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
  ),
);
