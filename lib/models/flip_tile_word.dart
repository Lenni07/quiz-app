import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FlipTileWord {
  final String word;
  final String clue;

  FlipTileWord({required this.word, required this.clue});

  factory FlipTileWord.fromJson(Map<String, dynamic> json) {
    return FlipTileWord(word: json['word'] as String, clue: json['clue'] as String);
  }
}

Future<List<FlipTileWord>> loadFlipTileWords() async {
  final jsonString = await rootBundle.loadString('assets/flip_tiles.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => FlipTileWord.fromJson(e as Map<String, dynamic>)).toList();
}
