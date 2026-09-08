import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';

class ImageQuizItem implements HasDepartment {
  final String icon;
  final List<String> options;
  final int correctIndex;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c). Fehlt das Feld,
  /// gilt die Aufgabe als allgemein.
  @override
  final String department;

  ImageQuizItem({
    required this.icon,
    required this.options,
    required this.correctIndex,
    this.department = 'general',
  });
}

Future<List<ImageQuizItem>> loadImageQuizItems() async {
  final jsonString = await rootBundle.loadString('assets/image_quiz.json');
  final List<dynamic> data = jsonDecode(jsonString);
  final random = Random();
  return data.map((e) {
    final json = e as Map<String, dynamic>;
    final correctAnswer = json['correctAnswer'] as String;
    final distractors = List<String>.from(json['distractors'] as List);
    final options = [correctAnswer, ...distractors]..shuffle(random);
    return ImageQuizItem(
      icon: json['icon'] as String,
      options: options,
      correctIndex: options.indexOf(correctAnswer),
      department: json['department'] as String? ?? 'general',
    );
  }).toList();
}
