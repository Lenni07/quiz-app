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

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.department = 'general',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      department: json['department'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'department': department,
    };
  }
}

Future<List<Question>> loadQuestions() async {
  final jsonString = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
}
