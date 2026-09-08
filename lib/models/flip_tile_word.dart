import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';

class FlipTileWord implements HasDepartment {
  final String word;
  final String clue;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c). Fehlt das Feld,
  /// gilt das Wort als allgemein.
  @override
  final String department;

  FlipTileWord({required this.word, required this.clue, this.department = 'general'});

  factory FlipTileWord.fromJson(Map<String, dynamic> json) {
    return FlipTileWord(
      word: json['word'] as String,
      clue: json['clue'] as String,
      department: json['department'] as String? ?? 'general',
    );
  }
}

Future<List<FlipTileWord>> loadFlipTileWords() async {
  final jsonString = await rootBundle.loadString('assets/flip_tiles.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => FlipTileWord.fromJson(e as Map<String, dynamic>)).toList();
}
