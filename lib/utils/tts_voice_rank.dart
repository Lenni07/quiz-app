/// Rangfolge für TTS-Stimmen (siehe ROADMAP_QuizApp.md Abschnitt 18g,
/// kurzfristiger Teil): 0 = netzbasierte Google-Stimme (klingt am
/// natürlichsten), 1 = andere Neural-/Online-/Premium-Stimme, 2 = alles
/// andere (i. d. R. die lokale Standard-Systemstimme). `flutter_tts`
/// liefert kein einheitliches "ist das eine Netz-/Premium-Stimme"-Flag über
/// alle Plattformen hinweg, deshalb wird das anhand des Stimmennamens
/// erkannt - Google/Microsoft benennen ihre besseren Stimmen durchgängig
/// entsprechend (z. B. "Google Deutsch", "Microsoft ... Online (Natural)").
int rankTtsVoiceName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('google')) return 0;
  if (lower.contains('neural') ||
      lower.contains('online') ||
      lower.contains('natural') ||
      lower.contains('premium') ||
      lower.contains('enhanced')) {
    return 1;
  }
  return 2;
}
