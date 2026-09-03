// Tests für die Department-Filterlogik (siehe ROADMAP_QuizApp.md Abschnitt
// 18c): Lernmodus zeigt eigenes Department + allgemeine Inhalte, 1 vs 1/
// Flottentreffen bewusst nur allgemeine Inhalte.
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/models/department.dart';
import 'package:rank_up/models/question.dart';

Question _q(String text, String department) {
  return Question(question: text, options: const ['a', 'b'], correctIndex: 0, department: department);
}

void main() {
  final questions = [
    _q('Allgemein 1', 'general'),
    _q('Allgemein 2', 'general'),
    _q('Restaurant 1', 'restaurant'),
    _q('Housekeeping 1', 'housekeeping'),
  ];

  group('questionsForLearning', () {
    test('ohne Department: keine Filterung', () {
      final result = questionsForLearning(questions, null);
      expect(result.length, 4);
    });

    test('mit Department: nur eigenes Department + allgemein', () {
      final result = questionsForLearning(questions, 'restaurant');
      expect(result.map((q) => q.question), containsAll(['Allgemein 1', 'Allgemein 2', 'Restaurant 1']));
      expect(result.any((q) => q.question == 'Housekeeping 1'), isFalse);
    });

    test('Department ohne eigene Inhalte: zeigt trotzdem die allgemeinen', () {
      final result = questionsForLearning(questions, 'security');
      expect(result.map((q) => q.question), ['Allgemein 1', 'Allgemein 2']);
    });

    test('weder Department- noch allgemeine Inhalte vorhanden: fällt auf ungefilterte Liste zurück', () {
      final onlyOtherDepartment = [_q('Restaurant 1', 'restaurant')];
      final result = questionsForLearning(onlyOtherDepartment, 'security');
      expect(result.length, 1);
    });
  });

  group('questionsForCompetitive', () {
    test('nur allgemeine Inhalte, keine Department-Fragen', () {
      final result = questionsForCompetitive(questions);
      expect(result.map((q) => q.question), ['Allgemein 1', 'Allgemein 2']);
    });

    test('ohne allgemeine Inhalte: fällt auf ungefilterte Liste zurück', () {
      final onlyDepartment = [_q('Restaurant 1', 'restaurant')];
      final result = questionsForCompetitive(onlyDepartment);
      expect(result.length, 1);
    });
  });
}
