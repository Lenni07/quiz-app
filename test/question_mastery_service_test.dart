// Tests für die Lernmodus-Fortschrittsanzeige (siehe ROADMAP_QuizApp.md
// Abschnitt 18e): Level-Fortschritt, Schwachstellen-Erkennung, Liste der
// noch nicht sicher sitzenden Fragen (lokal via SharedPreferences), sowie
// die Firestore-Sicherung/Wiederherstellung (gegen fake_cloud_firestore).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rank_up/models/question.dart';
import 'package:rank_up/services/question_mastery_service.dart';

Question _q(String id, String text, {int level = 1, String topic = 'Allgemein'}) {
  return Question(id: id, question: text, options: const ['a', 'b'], correctIndex: 0, level: level, topic: topic);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ohne jede Antwort: nichts gemeistert, keine Schwachstellen, alle Fragen offen', () async {
    final questions = [
      _q('q1', 'Frage 1', level: 1, topic: 'Artikel'),
      _q('q2', 'Frage 2', level: 2, topic: 'Kasus'),
    ];
    final progress = await QuestionMasteryService().computeProgress(questions);

    expect(progress.levels.map((l) => l.masteredCount), everyElement(0));
    expect(progress.weakestTopics, isEmpty);
    expect(progress.notYetMastered.length, 2);
  });

  test('zwei richtige Antworten in Folge gelten als gemeistert', () async {
    final question = _q('q1', 'Frage 1', level: 3, topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(question, wasCorrect: true);
    await service.recordAnswer(question, wasCorrect: true);

    final progress = await service.computeProgress([question]);
    expect(progress.levels.single.masteredCount, 1);
    expect(progress.notYetMastered, isEmpty);
  });

  test('eine falsche Antwort setzt den Streak zurück, zählt aber als Versuch', () async {
    final question = _q('q1', 'Frage 1', level: 1, topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(question, wasCorrect: true);
    await service.recordAnswer(question, wasCorrect: false);

    final progress = await service.computeProgress([question]);
    expect(progress.notYetMastered, [question]);
    expect(progress.weakestTopics.single.topic, 'Kasus');
    expect(progress.weakestTopics.single.masteredCount, 0);
    expect(progress.weakestTopics.single.attemptedCount, 1);
  });

  test('zwei verschiedene Fragen im selben Thema sammeln getrennte Statistiken', () async {
    final a = _q('q1', 'Frage A', topic: 'Kasus');
    final b = _q('q2', 'Frage B', topic: 'Kasus');
    final service = QuestionMasteryService();
    await service.recordAnswer(a, wasCorrect: true);
    await service.recordAnswer(a, wasCorrect: true);
    await service.recordAnswer(b, wasCorrect: false);

    final progress = await service.computeProgress([a, b]);
    expect(progress.notYetMastered, [b]);
    expect(progress.weakestTopics.single.masteredCount, 1);
    expect(progress.weakestTopics.single.attemptedCount, 2);
  });

  test('Schwachstellen sind nach Trefferquote sortiert, schwächstes Thema zuerst', () async {
    final weak = _q('q1', 'Dativ-Frage', level: 2, topic: 'Dativ-Präpositionen');
    final strong = _q('q2', 'Artikel-Frage', level: 1, topic: 'Artikel');
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
    final a = _q('q1', 'Frage A', level: 3, topic: 'Wortschatz');
    final b = _q('q2', 'Frage B', level: 3, topic: 'Kasus');
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

  group('Firestore-Sicherung/Wiederherstellung', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('recordAnswer sichert bei angemeldetem Nutzer im Hintergrund nach Firestore', () async {
      // Das Profil-Dokument existiert in der Praxis immer schon (siehe
      // ensureProfileExists() beim App-Start) - deshalb hier vorab angelegt,
      // wie es der echte Ablauf auch tut.
      await firestore.collection('users').doc('user-1').set({});
      final question = _q('q1', 'Frage 1');
      final service = QuestionMasteryService(firestore: firestore);
      await service.recordAnswer(question, wasCorrect: true, uid: 'user-1');
      // recordAnswer wartet den Cloud-Push nicht ab (fire-and-forget) - kurz
      // nachgeben, damit der Mikrotask sicher durchgelaufen ist.
      await Future.delayed(Duration.zero);

      final doc = await firestore.collection('users').doc('user-1').get();
      expect(doc.data()?['questionMastery']?['q1'], '1:1');
    });

    test('recordAnswer ohne uid schreibt nichts nach Firestore', () async {
      final question = _q('q1', 'Frage 1');
      final service = QuestionMasteryService(firestore: firestore);
      await service.recordAnswer(question, wasCorrect: true);
      await Future.delayed(Duration.zero);

      final doc = await firestore.collection('users').doc('user-1').get();
      expect(doc.exists, isFalse);
    });

    test('syncWithCloud holt Fortschritt von einem neuen Gerät zurück (leerer lokaler Speicher)', () async {
      final question = _q('q1', 'Frage 1');
      await firestore.collection('users').doc('user-1').set({
        'questionMastery': {'q1': '2:3'},
      });

      final service = QuestionMasteryService(firestore: firestore);
      await service.syncWithCloud('user-1', [question]);

      final progress = await service.computeProgress([question]);
      expect(progress.notYetMastered, isEmpty); // Streak 2 -> gemeistert
    });

    test('syncWithCloud überschreibt neueren lokalen Fortschritt nicht mit älterem Cloud-Stand', () async {
      final question = _q('q1', 'Frage 1');
      final service = QuestionMasteryService(firestore: firestore);
      // Lokal: drei Versuche, aktuell nicht gemeistert (letzte Antwort falsch).
      await service.recordAnswer(question, wasCorrect: true);
      await service.recordAnswer(question, wasCorrect: true);
      await service.recordAnswer(question, wasCorrect: false);
      // Cloud: nur ein einzelner (älterer) Versuch.
      await firestore.collection('users').doc('user-1').set({
        'questionMastery': {'q1': '1:1'},
      });

      await service.syncWithCloud('user-1', [question]);

      final progress = await service.computeProgress([question]);
      expect(progress.notYetMastered, [question]); // lokaler (aktuellerer) Stand bleibt erhalten

      final doc = await firestore.collection('users').doc('user-1').get();
      expect(doc.data()?['questionMastery']?['q1'], '0:3'); // Cloud wird auf lokalen Stand angehoben
    });

    test('syncWithCloud lässt bereits übereinstimmende Fragen unangetastet', () async {
      final question = _q('q1', 'Frage 1');
      final service = QuestionMasteryService(firestore: firestore);
      await service.recordAnswer(question, wasCorrect: true);
      await firestore.collection('users').doc('user-1').set({
        'questionMastery': {'q1': '1:1'},
      });

      await service.syncWithCloud('user-1', [question]);

      final doc = await firestore.collection('users').doc('user-1').get();
      expect(doc.data()?['questionMastery']?['q1'], '1:1');
    });
  });
}
