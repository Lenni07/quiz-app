import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

/// Anzahl aufeinanderfolgender richtiger Antworten, ab der eine Frage als
/// "sicher sitzend" gilt. Eine falsche Antwort setzt den Streak zurück - so
/// zählt nur, was gerade sicher sitzt, nicht was mal richtig geraten wurde.
const int masteredStreakThreshold = 2;

class _QuestionStats {
  final int streak;
  final int attempts;

  const _QuestionStats({required this.streak, required this.attempts});

  static const empty = _QuestionStats(streak: 0, attempts: 0);

  bool get everAttempted => attempts > 0;
  bool get isMastered => streak >= masteredStreakThreshold;

  String encode() => '$streak:$attempts';

  static _QuestionStats decode(String? raw) {
    if (raw == null) return empty;
    final parts = raw.split(':');
    if (parts.length != 2) return empty;
    return _QuestionStats(streak: int.tryParse(parts[0]) ?? 0, attempts: int.tryParse(parts[1]) ?? 0);
  }
}

/// Fortschritt für einen Level: wie viele der Fragen dieses Levels als
/// "sicher" gelten (siehe [masteredStreakThreshold]).
class LevelProgress {
  final int level;
  final int masteredCount;
  final int totalCount;

  LevelProgress({required this.level, required this.masteredCount, required this.totalCount});

  double get ratio => totalCount == 0 ? 0 : masteredCount / totalCount;
  int get percent => (ratio * 100).round();
}

/// Fortschritt für ein Thema (z. B. "Dativ-Präpositionen"): wie viele der
/// bereits versuchten Fragen dieses Themas sicher sitzen. Nur Themen mit
/// mindestens einem Versuch tauchen hier auf.
class TopicProgress {
  final String topic;
  final int masteredCount;
  final int attemptedCount;

  TopicProgress({required this.topic, required this.masteredCount, required this.attemptedCount});

  double get ratio => attemptedCount == 0 ? 1 : masteredCount / attemptedCount;
}

class LearningProgress {
  final List<LevelProgress> levels;
  final List<TopicProgress> weakestTopics;
  final List<Question> notYetMastered;

  LearningProgress({required this.levels, required this.weakestTopics, required this.notYetMastered});
}

/// Speichert pro Frage lokal auf dem Gerät (shared_preferences), wie oft sie
/// versucht wurde und wie lang die aktuelle Richtig-Serie ist (siehe
/// ROADMAP_QuizApp.md Abschnitt 18e) - das bleibt die für den laufenden
/// Betrieb genutzte Quelle, funktioniert also sofort und offline. Zusätzlich
/// wird bei jeder Antwort (wenn ein Nutzer angemeldet ist) im Hintergrund
/// nach Firestore gesichert (`users/{uid}.questionMastery`), damit der
/// Fortschritt bei Geräte-/App-Wechsel nicht verloren geht - [syncWithCloud]
/// gleicht lokalen und Cloud-Stand ab (z. B. beim Öffnen der
/// Fortschrittsanzeige). Nur für das Question-Modell (Allgemeinwissen-Quiz,
/// Gameshow-Quiz, Open the Box, Random Wheel, Duell), analog zum Scoping der
/// Department-Tags in Abschnitt 18c.
class QuestionMasteryService {
  QuestionMasteryService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  /// Erst bei tatsächlichem Cloud-Zugriff ausgewertet (nicht schon im
  /// Konstruktor) - sonst bräuchten auch rein lokale Aufrufe (computeProgress,
  /// recordAnswer ohne uid) ein initialisiertes Firebase, was z. B. in
  /// Tests ohne Firebase-Setup unnötig fehlschlagen würde.
  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  static const _keyPrefix = 'question_mastery_v1_';

  String _keyFor(Question question) => '$_keyPrefix${question.id}';

  Future<void> recordAnswer(Question question, {required bool wasCorrect, String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(question);
    final current = _QuestionStats.decode(prefs.getString(key));
    final updated = _QuestionStats(
      streak: wasCorrect ? current.streak + 1 : 0,
      attempts: current.attempts + 1,
    );
    await prefs.setString(key, updated.encode());
    if (uid != null && question.id.isNotEmpty) {
      unawaited(_pushToCloud(uid, question.id, updated));
    }
  }

  Future<void> _pushToCloud(String uid, String questionId, _QuestionStats stats) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'questionMastery.$questionId': stats.encode(),
      });
    } catch (_) {
      // Offline oder Profil-Dokument (noch) nicht vorhanden - lokaler
      // Fortschritt bleibt die maßgebliche Quelle, der nächste erfolgreiche
      // syncWithCloud()-Aufruf holt das nach.
    }
  }

  /// Gleicht lokalen und in Firestore gesicherten Fortschritt ab: pro Frage
  /// gewinnt die Seite mit mehr Versuchen (mehr Versuche = vollständigerer
  /// Verlauf), danach stehen beide Seiten auf demselben zusammengeführten
  /// Stand. Gedacht für z. B. einen Geräte-/App-Wechsel - lokal bleibt
  /// weiterhin die im laufenden Betrieb genutzte Quelle, das hier ist
  /// bewusst nur Sicherung/Wiederherstellung. Schlägt lautlos fehl (offline/
  /// kein Zugriff) - der nächste Aufruf, sobald wieder Verbindung besteht,
  /// holt den Abgleich nach.
  Future<void> syncWithCloud(String uid, List<Question> allQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> cloudMastery;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      cloudMastery = (doc.data()?['questionMastery'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return;
    }

    final mergedForCloud = <String, String>{};
    for (final question in allQuestions) {
      if (question.id.isEmpty) continue;
      final key = _keyFor(question);
      final local = _QuestionStats.decode(prefs.getString(key));
      final cloud = _QuestionStats.decode(cloudMastery[question.id] as String?);
      final winner = local.attempts >= cloud.attempts ? local : cloud;
      if (!identical(winner, local)) {
        await prefs.setString(key, winner.encode());
      }
      if (!identical(winner, cloud)) {
        mergedForCloud[question.id] = winner.encode();
      }
    }

    if (mergedForCloud.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).set(
          {'questionMastery': mergedForCloud},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Berechnet den Fortschritt über alle übergebenen Fragen - gedacht für
  /// den kompletten Fragenkatalog (nicht nur eine gespielte Runde), damit
  /// die Anzeige "60 % von Level 3" den ganzen Katalog widerspiegelt. Liest
  /// ausschließlich lokal, funktioniert also immer, auch offline.
  Future<LearningProgress> computeProgress(List<Question> allQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = <Question, _QuestionStats>{
      for (final q in allQuestions) q: _QuestionStats.decode(prefs.getString(_keyFor(q))),
    };

    final byLevel = <int, List<Question>>{};
    for (final q in allQuestions) {
      byLevel.putIfAbsent(q.level, () => []).add(q);
    }
    final levels = byLevel.entries.map((entry) {
      final mastered = entry.value.where((q) => stats[q]!.isMastered).length;
      return LevelProgress(level: entry.key, masteredCount: mastered, totalCount: entry.value.length);
    }).toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    final byTopic = <String, List<Question>>{};
    for (final q in allQuestions) {
      byTopic.putIfAbsent(q.topic, () => []).add(q);
    }
    final topics = byTopic.entries
        .map((entry) {
          final attempted = entry.value.where((q) => stats[q]!.everAttempted).toList();
          return TopicProgress(
            topic: entry.key,
            masteredCount: attempted.where((q) => stats[q]!.isMastered).length,
            attemptedCount: attempted.length,
          );
        })
        .where((t) => t.attemptedCount > 0)
        .toList()
      ..sort((a, b) => a.ratio.compareTo(b.ratio));

    final notYetMastered = allQuestions.where((q) => !stats[q]!.isMastered).toList();

    return LearningProgress(
      levels: levels,
      weakestTopics: topics.take(3).toList(),
      notYetMastered: notYetMastered,
    );
  }
}
