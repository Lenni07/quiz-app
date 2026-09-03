import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprache der Bedienoberfläche (Menüs, Reiter, Buttons, Texte - siehe
/// ROADMAP_QuizApp.md Abschnitt 19). Die deutschen Lerninhalte/Fragen selbst
/// bleiben davon unberührt, immer Deutsch.
enum AppLanguage { de, en }

const _prefsKey = 'uiLanguage';

/// Globaler, ambienter Zustand statt Provider/Riverpod (wie schon
/// GameModeContext/MatchRoundContext in diesem Projekt) - MyApp hört per
/// ValueListenableBuilder zu und baut beim Wechsel die ganze Oberfläche neu.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.de);

/// Lädt die zuletzt gespeicherte Sprache (falls vorhanden) - unabhängig von
/// Firebase, funktioniert also auch offline sofort beim Start.
Future<void> loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'en') appLanguage.value = AppLanguage.en;
  } catch (_) {
    // Kein Speicherzugriff möglich - Standard (Deutsch) bleibt aktiv.
  }
}

Future<void> setAppLanguage(AppLanguage language) async {
  appLanguage.value = language;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  } catch (_) {
    // Wird dann nur für diese Sitzung gemerkt, kein harter Fehler.
  }
}
