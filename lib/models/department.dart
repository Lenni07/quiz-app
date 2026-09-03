import 'question.dart';

/// Department-Tags für Fragen (siehe ROADMAP_QuizApp.md Abschnitt 18c).
/// Erster Durchgang: nur das Question-Modell bekommt Tags (genutzt von
/// Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box, Random Wheel). Die
/// übrigen Datenmodelle (Sentence, TrueFalse, ImageQuiz, GroupSort,
/// FlipTileWord, NumberWord) müssen das Department-Feld bekommen, BEVOR
/// echte Inhalte eingepflegt werden - siehe Warnhinweis in Abschnitt 18c.
const String generalDepartmentId = 'general';

const List<String> departmentIds = ['restaurant', 'housekeeping', 'rezeption', 'spa', 'security'];

/// Fragen für den Lernmodus: eigenes Department + allgemeine Inhalte. Ohne
/// gesetztes Department (oder unbekannter Wert) gibt es keinen Filter - alle
/// Fragen sind sichtbar. Fällt auf die ungefilterte Liste zurück, falls der
/// Filter (noch) nichts träfe - sonst stünde ein Nutzer ganz ohne Fragen da,
/// solange kaum Inhalte für sein Department getaggt sind.
List<Question> questionsForLearning(List<Question> all, String? userDepartment) {
  if (userDepartment == null || !departmentIds.contains(userDepartment)) {
    return List.of(all);
  }
  final filtered = all.where((q) => q.department == generalDepartmentId || q.department == userDepartment).toList();
  return filtered.isEmpty ? List.of(all) : filtered;
}

/// Fragen für 1 vs 1 / Flottentreffen: bewusst NUR allgemeine, abteilungs-
/// übergreifende Inhalte (siehe ROADMAP_QuizApp.md Abschnitt 18c) - es wird
/// nicht nach Department gematcht, beide Seiten haben dieselben
/// Voraussetzungen. Gleiches Sicherheitsnetz wie oben.
List<Question> questionsForCompetitive(List<Question> all) {
  final general = all.where((q) => q.department == generalDepartmentId).toList();
  return general.isEmpty ? List.of(all) : general;
}
