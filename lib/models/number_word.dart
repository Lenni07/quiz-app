import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NumberWord {
  final String word;
  final int value;

  NumberWord({required this.word, required this.value});

  factory NumberWord.fromJson(Map<String, dynamic> json) {
    return NumberWord(word: json['word'] as String, value: json['value'] as int);
  }
}

Future<List<NumberWord>> loadNumberWords() async {
  final jsonString = await rootBundle.loadString('assets/number_words.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => NumberWord.fromJson(e as Map<String, dynamic>)).toList();
}
