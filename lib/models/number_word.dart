import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';

class NumberWord implements HasDepartment {
  final String word;
  final int value;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c). Fehlt das Feld,
  /// gilt das Zahlwort als allgemein.
  @override
  final String department;

  NumberWord({required this.word, required this.value, this.department = 'general'});

  factory NumberWord.fromJson(Map<String, dynamic> json) {
    return NumberWord(
      word: json['word'] as String,
      value: json['value'] as int,
      department: json['department'] as String? ?? 'general',
    );
  }
}

Future<List<NumberWord>> loadNumberWords() async {
  final jsonString = await rootBundle.loadString('assets/number_words.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => NumberWord.fromJson(e as Map<String, dynamic>)).toList();
}
