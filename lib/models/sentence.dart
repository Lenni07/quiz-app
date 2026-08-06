import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'question.dart';

class Sentence {
  final String question;
  final String correctAnswer;
  final List<String> distractors;

  Sentence({
    required this.question,
    required this.correctAnswer,
    required this.distractors,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      distractors: List<String>.from(json['distractors'] as List),
    );
  }
}

Future<List<Sentence>> loadSentences() async {
  final jsonString = await rootBundle.loadString('assets/sentences.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => Sentence.fromJson(e as Map<String, dynamic>)).toList();
}

/// Wandelt Sätze in Question-Objekte um (Antwortoptionen gemischt), damit
/// der bestehende Frage-Bildschirm ohne Änderungen wiederverwendet werden kann.
List<Question> sentencesToQuestions(List<Sentence> sentences) {
  final random = Random();
  return sentences.map((sentence) {
    final options = [sentence.correctAnswer, ...sentence.distractors]..shuffle(random);
    return Question(
      question: sentence.question,
      options: options,
      correctIndex: options.indexOf(sentence.correctAnswer),
    );
  }).toList();
}
