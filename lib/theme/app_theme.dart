import 'package:flutter/material.dart';

/// Einheitliches Farbschema der App (dunkles Meer & Sonnenuntergang).
class AppColors {
  static const primary = Color(0xFF01579B); // Meeresblau
  static const accent = Color(0xFFFF8A50); // Sonnenuntergangs-Orange
  static const background = Color(0xFF0B2033); // dunkles Nachtblau
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.background,
    brightness: Brightness.dark,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
