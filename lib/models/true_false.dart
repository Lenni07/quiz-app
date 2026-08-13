import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TrueFalseStatement {
  final String statement;
  final bool isTrue;

  TrueFalseStatement({required this.statement, required this.isTrue});

  factory TrueFalseStatement.fromJson(Map<String, dynamic> json) {
    return TrueFalseStatement(
      statement: json['statement'] as String,
      isTrue: json['isTrue'] as bool,
    );
  }
}

Future<List<TrueFalseStatement>> loadTrueFalseStatements() async {
  final jsonString = await rootBundle.loadString('assets/true_false.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => TrueFalseStatement.fromJson(e as Map<String, dynamic>)).toList();
}
