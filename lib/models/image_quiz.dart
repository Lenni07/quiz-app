import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class ImageQuizItem {
  final String icon;
  final List<String> options;
  final int correctIndex;

  ImageQuizItem({required this.icon, required this.options, required this.correctIndex});
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
    );
  }).toList();
}
