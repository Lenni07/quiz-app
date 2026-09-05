// Tests für die Lernmodus-Fortschrittsanzeige (siehe ROADMAP_QuizApp.md
// Abschnitt 18e): Level-Fortschritt, Schwachstellen-Erkennung und Liste der
// noch nicht sicher sitzenden Fragen, rein lokal via SharedPreferences.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rank_up/models/question.dart';
import 'package:rank_up/services/question_mastery_service.dart';

Question _q(String text, {int level = 1, String topic = 'Allgemein'}) {
  return Question(question: text, options: const ['a', 'b'], correctIndex: 0, level: level, topic: topic);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ohne jede Antwort: nichts gemeistert, keine Schwachstellen, alle Fragen offen', () async {
    final questions = [
      _q('Frage 1', level: 1, topic: 'Artikel'),
      _q('Frage 2', level: 2, topic: 'Kasus'),
    ];
    final progress = await QuestionMasteryService().computeProgress(questions);

    expect(progress.levels.map((l) => l.masteredCount), everyElement(0));
    expect(progress.weakestTopics, isEmpty);
    expect(progress.notYetMastered.length, 2);
  });

  test('zwei richtige Antworten in Folge gelten als gemeistert', () async {
    final question = _q('Frage 1', level: 3, topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(question, wasCorrect: true);
    await service.recordAnswer(question, wasCorrect: true);

    final progress = await service.computeProgress([question]);
    expect(progress.levels.single.masteredCount, 1);
    expect(progress.notYetMastered, isEmpty);
  });

  test('eine falsche Antwort setzt den Streak zurück, zählt aber als Versuch', () async {
    final question = _q('Frage 1', level: 1, topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(question, wasCorrect: true);
    await service.recordAnswer(question, wasCorrect: false);

    final progress = await service.computeProgress([question]);
    expect(progress.notYetMastered, [question]);
    expect(progress.weakestTopics.single.topic, 'Kasus');
    expect(progress.weakestTopics.single.masteredCount, 0);
    expect(progress.weakestTopics.single.attemptedCount, 1);
  });

  test('Schwachstellen sind nach Trefferquote sortiert, schwächstes Thema zuerst', () async {
    final weak = _q('Dativ-Frage', level: 2, topic: 'Dativ-Präpositionen');
    final strong = _q('Artikel-Frage', level: 1, topic: 'Artikel');
    final service = QuestionMasteryService();

    // Dativ: 1 von 2 Versuchen richtig-genug (0 von 1 gemeistert, da Streak
    // durch die falsche Antwort zuletzt zurückgesetzt wurde).
    await service.recordAnswer(weak, wasCorrect: true);
    await service.recordAnswer(weak, wasCorrect: false);
    // Artikel: zweimal richtig in Folge -> gemeistert.
    await service.recordAnswer(strong, wasCorrect: true);
    await service.recordAnswer(strong, wasCorrect: true);

    final progress = await service.computeProgress([weak, strong]);
    expect(progress.weakestTopics.first.topic, 'Dativ-Präpositionen');
    expect(progress.weakestTopics.last.topic, 'Artikel');
  });

  test('Level-Fortschritt gruppiert korrekt nach Level, unabhängig vom Thema', () async {
    final a = _q('Frage A', level: 3, topic: 'Wortschatz');
    final b = _q('Frage B', level: 3, topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(a, wasCorrect: true);
    await service.recordAnswer(a, wasCorrect: true);

    final progress = await service.computeProgress([a, b]);
    final level3 = progress.levels.single;
    expect(level3.level, 3);
    expect(level3.masteredCount, 1);
    expect(level3.totalCount, 2);
    expect(level3.percent, 50);
  });
}
