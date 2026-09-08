// Tests für die Department-Filterlogik (siehe ROADMAP_QuizApp.md Abschnitt
// 18c): Lernmodus zeigt eigenes Department + allgemeine Inhalte, 1 vs 1 /
// Flottentreffen / lokales Duell bewusst nur allgemeine Inhalte. Gilt jetzt
// generisch für alle Inhaltsmodelle (HasDepartment), nicht nur Question.
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/models/department.dart';
import 'package:rank_up/models/flip_tile_word.dart';
import 'package:rank_up/models/image_quiz.dart';
import 'package:rank_up/models/number_word.dart';
import 'package:rank_up/models/question.dart';
import 'package:rank_up/models/sentence.dart';
import 'package:rank_up/models/true_false.dart';

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
      expect(questionsForLearning(questions, null).length, 4);
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

    test('weder Department- noch allgemeine Inhalte: fällt auf ungefilterte Liste zurück', () {
      final result = questionsForLearning([_q('Restaurant 1', 'restaurant')], 'security');
      expect(result.length, 1);
    });
  });

  group('questionsForCompetitive', () {
    test('nur allgemeine Inhalte', () {
      expect(questionsForCompetitive(questions).map((q) => q.question), ['Allgemein 1', 'Allgemein 2']);
    });

    test('ohne allgemeine Inhalte: fällt auf ungefilterte Liste zurück', () {
      expect(questionsForCompetitive([_q('Restaurant 1', 'restaurant')]).length, 1);
    });
  });

  group('contentForLearning/Competitive generisch (nicht nur Question)', () {
    final numbers = [
      NumberWord(word: 'eins', value: 1), // default general
      NumberWord(word: 'Suite', value: 2, department: 'housekeeping'),
      NumberWord(word: 'Tisch 3', value: 3, department: 'restaurant'),
    ];

    test('Lernmodus: eigenes Department + allgemein', () {
      final r = contentForLearning(numbers, 'housekeeping');
      expect(r.map((n) => n.word), ['eins', 'Suite']);
    });

    test('Wettkampf: nur general', () {
      expect(contentForCompetitive(numbers).map((n) => n.word), ['eins']);
    });

    test('funktioniert auch mit Sentence/TrueFalse/ImageQuiz/FlipTileWord', () {
      final mixed = <TrueFalseStatement>[
        TrueFalseStatement(statement: 'a', isTrue: true),
        TrueFalseStatement(statement: 'b', isTrue: false, department: 'spa'),
      ];
      expect(contentForCompetitive(mixed).length, 1);
      expect(contentForLearning(mixed, 'spa').length, 2);
    });
  });

  group('Department wird aus JSON gelesen, Standard "general"', () {
    test('Sentence', () {
      expect(Sentence.fromJson({
        'question': 'q', 'correctAnswer': 'ein zwei', 'distractors': ['x'], 'blankIndex': 0,
      }).department, 'general');
      expect(Sentence.fromJson({
        'question': 'q', 'correctAnswer': 'ein zwei', 'distractors': ['x'], 'blankIndex': 0,
        'department': 'rezeption',
      }).department, 'rezeption');
    });

    test('TrueFalseStatement', () {
      expect(TrueFalseStatement.fromJson({'statement': 's', 'isTrue': true}).department, 'general');
      expect(
        TrueFalseStatement.fromJson({'statement': 's', 'isTrue': true, 'department': 'security'}).department,
        'security',
      );
    });

    test('FlipTileWord', () {
      expect(FlipTileWord.fromJson({'word': 'W', 'clue': 'c'}).department, 'general');
      expect(FlipTileWord.fromJson({'word': 'W', 'clue': 'c', 'department': 'spa'}).department, 'spa');
    });

    test('NumberWord', () {
      expect(NumberWord.fromJson({'word': 'eins', 'value': 1}).department, 'general');
      expect(NumberWord.fromJson({'word': 'eins', 'value': 1, 'department': 'restaurant'}).department, 'restaurant');
    });

    test('ImageQuizItem (Standard über Konstruktor)', () {
      expect(ImageQuizItem(icon: 'i', options: const ['a'], correctIndex: 0).department, 'general');
    });
  });

  test('sentencesToQuestions übernimmt das Department', () {
    final s = Sentence(
      question: 'q', correctAnswer: 'ein zwei', distractors: const ['x'], blankIndex: 0,
      department: 'housekeeping',
    );
    expect(sentencesToQuestions([s]).single.department, 'housekeeping');
  });
}
