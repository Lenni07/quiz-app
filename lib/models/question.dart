import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}

Future<List<Question>> loadQuestions() async {
  final jsonString = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
}
