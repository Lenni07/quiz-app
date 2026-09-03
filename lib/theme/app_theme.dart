import 'package:flutter/material.dart';

/// Maritime Farbpalette (siehe ROADMAP_QuizApp.md Abschnitt 13/13a/13b):
/// Tiefseeblau als Basis, Messing/Gold für Buttons/Akzente, Segeltuch-Beige
/// für helle Flächen/Text auf dunklem Grund, Signalrot als Warn-/Akzentfarbe.
/// Ersetzt das bisherige einfarbige Blau-auf-Dunkelblau.
class AppColors {
  static const deepSea = Color(0xFF0B3D5C);
  static const deepSeaLight = Color(0xFF1C6690);
  static const deepSeaDark = Color(0xFF071B29);

  static const brass = Color(0xFFC9A227);
  static const brassLight = Color(0xFFE6C158);
  static const brassDark = Color(0xFF8F6F14);

  static const canvas = Color(0xFFE8DCC0);
  static const canvasDark = Color(0xFFC9B98D);

  static const signalRed = Color(0xFFD7263D);

  /// Alte Namen bleiben als Aliase erhalten, damit nicht jede Verwendung im
  /// Code angepasst werden muss (z. B. flutter_native_splash-Konfiguration).
  static const primary = deepSea;
  static const accent = brass;
  static const background = deepSeaDark;

  static const buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brassLight, brass, brassDark],
    stops: [0.0, 0.5, 1.0],
  );

  static const panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepSeaLight, deepSea],
  );
}

/// Name der gebündelten Display-Schrift (siehe pubspec.yaml) - fett und
/// charaktervoll für Überschriften/Buttons/Zahlen. Fließtext (Fragen,
/// Anleitungen) bleibt bewusst auf der Systemschrift, damit lange deutsche
/// Sätze gut lesbar bleiben.
const String displayFontFamily = 'Baloo2';

TextStyle displayStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: displayFontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.deepSea,
    primary: AppColors.deepSea,
    onPrimary: AppColors.canvas,
    secondary: AppColors.brass,
    onSecondary: AppColors.deepSeaDark,
    tertiary: AppColors.signalRed,
    surface: AppColors.deepSeaDark,
    error: AppColors.signalRed,
    brightness: Brightness.dark,
  );

  final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w800),
    displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w800),
    displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w700),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w700),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w700),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w700),
    titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w700),
    titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w600),
    titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: displayFontFamily, fontWeight: FontWeight.w600),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontFamily: displayFontFamily,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    ),
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.deepSea,
      foregroundColor: AppColors.canvas,
      elevation: 4,
      shadowColor: Colors.black54,
      titleTextStyle: displayStyle(fontSize: 20, color: AppColors.canvas),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.deepSeaDark,
        disabledBackgroundColor: AppColors.brass.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: displayStyle(fontSize: 16, letterSpacing: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        shadowColor: Colors.black87,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.canvas,
        side: const BorderSide(color: AppColors.brass, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: displayStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.deepSeaLight.withValues(alpha: 0.28),
      elevation: 6,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.brass.withValues(alpha: 0.25)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brass,
      linearTrackColor: Color(0x33E8DCC0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.deepSeaLight.withValues(alpha: 0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.brass.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brass, width: 2),
      ),
    ),
  );
}
