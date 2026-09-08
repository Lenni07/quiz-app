import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';
import 'question.dart';

class SentenceTranslation {
  final String question;
  final String answer;

  SentenceTranslation({required this.question, required this.answer});

  factory SentenceTranslation.fromJson(Map<String, dynamic> json) {
    return SentenceTranslation(
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

class Sentence implements HasDepartment {
  final String question;
  final String correctAnswer;
  final List<String> distractors;
  final int blankIndex;
  final Map<String, SentenceTranslation> translations;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c). Fehlt das Feld,
  /// gilt der Satz als allgemein.
  @override
  final String department;

  Sentence({
    required this.question,
    required this.correctAnswer,
    required this.distractors,
    required this.blankIndex,
    this.translations = const {},
    this.department = 'general',
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    final translationsJson = json['translations'] as Map<String, dynamic>?;
    return Sentence(
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      distractors: List<String>.from(json['distractors'] as List),
      blankIndex: json['blankIndex'] as int,
      department: json['department'] as String? ?? 'general',
      translations: translationsJson == null
          ? const {}
          : translationsJson.map(
              (code, value) => MapEntry(code, SentenceTranslation.fromJson(value as Map<String, dynamic>)),
            ),
    );
  }

  List<String> get words => correctAnswer.split(' ');

  String get blankWord => words[blankIndex];

  /// Der Satz mit "___" statt des zu erratenden Worts.
  String get blankedSentence {
    return words.asMap().entries.map((entry) {
      return entry.key == blankIndex ? '___' : entry.value;
    }).join(' ');
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
      department: sentence.department,
    );
  }).toList();
}
