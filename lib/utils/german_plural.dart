/// Einfache Singular-/Pluralwahl für die (bewusst unübersetzt gebliebenen,
/// siehe ROADMAP_QuizApp.md Abschnitt 19) deutschen Format-Bildschirm-Texte
/// - z. B. "1 Versuch" vs. "3 Versuche". Für die übersetzte App-Hülle gibt
/// es stattdessen `S.plural()` in lib/l10n/strings.dart.
String germanCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}
