import 'has_department.dart';
import 'question.dart';

export 'has_department.dart';

/// Department-Tags für Lerninhalte (siehe ROADMAP_QuizApp.md Abschnitt 18c).
/// Alle Inhaltsmodelle (Question, Sentence, TrueFalseStatement, ImageQuizItem,
/// GroupSortData, FlipTileWord, NumberWord) implementieren [HasDepartment].
const String generalDepartmentId = 'general';

const List<String> departmentIds = ['restaurant', 'housekeeping', 'rezeption', 'spa', 'security'];

/// Inhalte für den Lernmodus: eigenes Department + allgemeine Inhalte. Ohne
/// gesetztes Department (oder unbekannter Wert) gibt es keinen Filter - alles
/// ist sichtbar. Fällt auf die ungefilterte Liste zurück, falls der Filter
/// (noch) nichts träfe - sonst stünde ein Nutzer ganz ohne Inhalte da,
/// solange kaum etwas für sein Department getaggt ist.
List<T> contentForLearning<T extends HasDepartment>(List<T> all, String? userDepartment) {
  if (userDepartment == null || !departmentIds.contains(userDepartment)) {
    return List.of(all);
  }
  final filtered = all
      .where((e) => e.department == generalDepartmentId || e.department == userDepartment)
      .toList();
  return filtered.isEmpty ? List.of(all) : filtered;
}

/// Inhalte für 1 vs 1 / Flottentreffen / lokales Duell: bewusst NUR
/// allgemeine, abteilungsübergreifende Inhalte (siehe ROADMAP_QuizApp.md
/// Abschnitt 18c) - es wird nicht nach Department gematcht, beide Seiten
/// haben dieselben Voraussetzungen. Gleiches Sicherheitsnetz wie oben.
List<T> contentForCompetitive<T extends HasDepartment>(List<T> all) {
  final general = all.where((e) => e.department == generalDepartmentId).toList();
  return general.isEmpty ? List.of(all) : general;
}

// Rückwärtskompatible Kurzformen für das Question-Modell (bestehende Aufrufer
// und Tests). Nur dünne Weiterleitungen auf die generischen Helfer.
List<Question> questionsForLearning(List<Question> all, String? userDepartment) =>
    contentForLearning(all, userDepartment);

List<Question> questionsForCompetitive(List<Question> all) => contentForCompetitive(all);
