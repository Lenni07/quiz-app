import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c), z. B.
  /// "restaurant", "housekeeping" - oder "general" für abteilungsüber-
  /// greifende Inhalte. Fehlt das Feld in den Rohdaten, gilt die Frage als
  /// allgemein.
  final String department;

  /// Berlitz-Level (1-6, siehe ROADMAP_QuizApp.md Abschnitt 18e), zu dem die
  /// Frage inhaltlich passt - Grundlage für die Fortschrittsanzeige im
  /// Lernmodus. Fehlt das Feld, gilt Level 1 als Standard.
  final int level;

  /// Grammatisches/thematisches Schlagwort (z. B. "Kasus", "Artikel",
  /// "Höflichkeitsformen") für die Schwachstellen-Erkennung im Lernmodus.
  /// Fehlt das Feld, gilt "Allgemein".
  final String topic;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.department = 'general',
    this.level = 1,
    this.topic = 'Allgemein',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      department: json['department'] as String? ?? 'general',
      level: json['level'] as int? ?? 1,
      topic: json['topic'] as String? ?? 'Allgemein',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'department': department,
      'level': level,
      'topic': topic,
    };
  }
}

Future<List<Question>> loadQuestions() async {
  final jsonString = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
}
