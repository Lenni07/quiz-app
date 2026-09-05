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

/// Speichert pro Frage lokal auf dem Gerät, wie oft sie versucht wurde und
/// wie lang die aktuelle Richtig-Serie ist (siehe ROADMAP_QuizApp.md
/// Abschnitt 18e) - bewusst KEIN Firestore/Server, da der Lernmodus
/// offline-first funktionieren soll und keine EP vergibt. Nur für das
/// Question-Modell (Allgemeinwissen-Quiz, Gameshow-Quiz, Open the Box,
/// Random Wheel), analog zum Scoping der Department-Tags in Abschnitt 18c.
class QuestionMasteryService {
  static const _keyPrefix = 'question_mastery_v1_';

  String _keyFor(Question question) => '$_keyPrefix${question.question.hashCode}';

  Future<void> recordAnswer(Question question, {required bool wasCorrect}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(question);
    final current = _QuestionStats.decode(prefs.getString(key));
    final updated = _QuestionStats(
      streak: wasCorrect ? current.streak + 1 : 0,
      attempts: current.attempts + 1,
    );
    await prefs.setString(key, updated.encode());
  }

  /// Berechnet den Fortschritt über alle übergebenen Fragen - gedacht für
  /// den kompletten Fragenkatalog (nicht nur eine gespielte Runde), damit
  /// die Anzeige "60 % von Level 3" den ganzen Katalog widerspiegelt.
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
