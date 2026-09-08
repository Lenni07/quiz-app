import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'has_department.dart';

class TrueFalseStatement implements HasDepartment {
  final String statement;
  final bool isTrue;

  /// Department-Tag (siehe ROADMAP_QuizApp.md Abschnitt 18c). Fehlt das Feld,
  /// gilt die Aussage als allgemein.
  @override
  final String department;

  TrueFalseStatement({
    required this.statement,
    required this.isTrue,
    this.department = 'general',
  });

  factory TrueFalseStatement.fromJson(Map<String, dynamic> json) {
    return TrueFalseStatement(
      statement: json['statement'] as String,
      isTrue: json['isTrue'] as bool,
      department: json['department'] as String? ?? 'general',
    );
  }
}

Future<List<TrueFalseStatement>> loadTrueFalseStatements() async {
  final jsonString = await rootBundle.loadString('assets/true_false.json');
  final List<dynamic> data = jsonDecode(jsonString);
  return data.map((e) => TrueFalseStatement.fromJson(e as Map<String, dynamic>)).toList();
}
