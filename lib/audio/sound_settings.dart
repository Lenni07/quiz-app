import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ob Antwort-/Button-Sounds spielen sollen (siehe ROADMAP_QuizApp.md
/// Abschnitt 18e) - wichtig als Stummschalt-Option für gemeinsame Räume an
/// Bord. Gleiches Muster wie [appLanguage] in l10n/app_language.dart:
/// globaler ambienter Zustand statt Provider/Riverpod, lokal per
/// shared_preferences gemerkt, funktioniert unabhängig von Firebase.
const _prefsKey = 'soundEnabled';

final ValueNotifier<bool> soundEnabled = ValueNotifier(true);

Future<void> loadSavedSoundSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey);
    if (saved != null) soundEnabled.value = saved;
  } catch (_) {
    // Kein Speicherzugriff möglich - Standard (an) bleibt aktiv.
  }
}

Future<void> setSoundEnabled(bool enabled) async {
  soundEnabled.value = enabled;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  } catch (_) {
    // Wird dann nur für diese Sitzung gemerkt, kein harter Fehler.
  }
}
