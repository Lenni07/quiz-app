// Tests für die Platzhalter-Fragen (siehe ROADMAP_QuizApp.md Abschnitt
// 18f): Altersberechnung, Platzhalter-Auflösung (einfach + geschlechts-
// abhängig), Fragen-Erzeugung und die Filterung auf "sinnvoll ausfüllbar".
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/models/personalized_question.dart';

PersonalizedQuestionTemplate _template({
  String id = 't1',
  required String question,
  required String correctAnswer,
  List<String> decoyPool = const ['a', 'b', 'c', 'd'],
}) {
  return PersonalizedQuestionTemplate(id: id, questionTemplate: question, correctAnswerTemplate: correctAnswer, decoyPool: decoyPool);
}

void main() {
  group('calculateAge', () {
    test('Geburtstag dieses Jahr schon vorbei', () {
      expect(calculateAge(DateTime(2000, 1, 1), now: DateTime(2026, 6, 15)), 26);
    });

    test('Geburtstag dieses Jahr noch nicht erreicht', () {
      expect(calculateAge(DateTime(2000, 12, 31), now: DateTime(2026, 6, 15)), 25);
    });

    test('genau am Geburtstag', () {
      expect(calculateAge(DateTime(2000, 6, 15), now: DateTime(2026, 6, 15)), 26);
    });
  });

  group('fillTemplate', () {
    const profile = PersonalizationProfile(
      firstName: 'Maria',
      age: 29,
      position: 'Kellnerin',
      grammaticalForm: 'female',
    );

    test('einfache Platzhalter werden aus dem Profil ersetzt', () {
      expect(fillTemplate('Hallo {vorname}, du bist {alter} Jahre alt.', profile), 'Hallo Maria, du bist 29 Jahre alt.');
      expect(fillTemplate('Deine Position: {position}.', profile), 'Deine Position: Kellnerin.');
    });

    test('geschlechtsabhängige Form: weiblich wählt den Teil nach dem Schrägstrich', () {
      expect(fillTemplate('Du bist {Kellner/Kellnerin}.', profile), 'Du bist Kellnerin.');
    });

    test('geschlechtsabhängige Form: männlich wählt den Teil vor dem Schrägstrich', () {
      const maleProfile = PersonalizationProfile(firstName: 'Tom', age: 30, position: 'Kellner', grammaticalForm: 'male');
      expect(fillTemplate('Du bist {Kellner/Kellnerin}.', maleProfile), 'Du bist Kellner.');
    });

    test('fehlende Angabe lässt den Platzhalter unverändert stehen', () {
      const incomplete = PersonalizationProfile(firstName: '', age: null, position: '', grammaticalForm: null);
      expect(fillTemplate('Hallo {vorname}!', incomplete), 'Hallo {vorname}!');
      expect(fillTemplate('Du bist {Kellner/Kellnerin}.', incomplete), 'Du bist {Kellner/Kellnerin}.');
    });

    test('unbekannter Platzhalter bleibt unverändert', () {
      expect(fillTemplate('Wert: {unbekannt}', profile), 'Wert: {unbekannt}');
    });
  });

  group('usableTemplates', () {
    const complete = PersonalizationProfile(firstName: 'Maria', age: 29, position: 'Kellnerin', grammaticalForm: 'female');
    const noAge = PersonalizationProfile(firstName: 'Maria', age: null, position: 'Kellnerin', grammaticalForm: 'female');
    const noForm = PersonalizationProfile(firstName: 'Maria', age: 29, position: 'Kellnerin', grammaticalForm: null);

    test('vollständiges Profil: alle Vorlagen nutzbar', () {
      final templates = [
        _template(question: 'Wie heißt du?', correctAnswer: '{vorname}'),
        _template(id: 't2', question: 'Wie alt bist du?', correctAnswer: '{alter}'),
        _template(id: 't3', question: 'Dein Beruf?', correctAnswer: '{Kellner/Kellnerin}'),
      ];
      expect(usableTemplates(templates, complete).length, 3);
    });

    test('fehlendes Alter filtert nur die Alters-Vorlage heraus', () {
      final templates = [
        _template(question: 'Wie heißt du?', correctAnswer: '{vorname}'),
        _template(id: 't2', question: 'Wie alt bist du?', correctAnswer: '{alter}'),
      ];
      final usable = usableTemplates(templates, noAge);
      expect(usable.length, 1);
      expect(usable.single.id, 't1');
    });

    test('fehlende grammatische Form filtert geschlechtsabhängige Vorlagen heraus', () {
      final templates = [
        _template(question: 'Wie heißt du?', correctAnswer: '{vorname}'),
        _template(id: 't2', question: 'Dein Beruf?', correctAnswer: '{Kellner/Kellnerin}'),
      ];
      final usable = usableTemplates(templates, noForm);
      expect(usable.length, 1);
      expect(usable.single.id, 't1');
    });
  });

  group('buildPersonalizedQuestion', () {
    const profile = PersonalizationProfile(firstName: 'Maria', age: 29, position: 'Kellnerin', grammaticalForm: 'female');

    test('die richtige Antwort steht unter den Optionen und correctIndex zeigt darauf', () {
      final template = _template(question: 'Wie heißt du?', correctAnswer: '{vorname}', decoyPool: ['Julia', 'Anna', 'Lea', 'Tom']);
      final question = buildPersonalizedQuestion(template, profile, random: Random(1));
      expect(question.options[question.correctIndex], 'Maria');
      expect(question.options.length, 4);
    });

    test('Falsch-Antworten schließen die richtige Antwort aus, auch bei Namensgleichheit', () {
      final template = _template(question: 'Wie heißt du?', correctAnswer: '{vorname}', decoyPool: ['Maria', 'Julia', 'Anna', 'Lea']);
      final question = buildPersonalizedQuestion(template, profile, random: Random(2));
      final wrongOptions = List.of(question.options)..removeAt(question.correctIndex);
      expect(wrongOptions, isNot(contains('Maria')));
    });

    test('geschlechtsabhängige Falsch-Antworten werden ebenfalls passend aufgelöst', () {
      final template = _template(
        question: 'Dein Beruf?',
        correctAnswer: '{Kellner/Kellnerin}',
        decoyPool: ['{Koch/Köchin}', '{Barkeeper/Barkeeperin}'],
      );
      final question = buildPersonalizedQuestion(template, profile, random: Random(3));
      expect(question.options, contains('Kellnerin'));
      expect(question.options.any((o) => o.contains('/')), isFalse);
    });

    test('id/level/topic der Vorlage landen auf der erzeugten Frage', () {
      final template = PersonalizedQuestionTemplate(
        id: 'abc',
        questionTemplate: 'Wie heißt du?',
        correctAnswerTemplate: '{vorname}',
        decoyPool: const ['Julia', 'Anna', 'Lea'],
        level: 3,
        topic: 'Testthema',
      );
      final question = buildPersonalizedQuestion(template, profile, random: Random(4));
      expect(question.id, 'personal_abc');
      expect(question.level, 3);
      expect(question.topic, 'Testthema');
    });
  });
}
