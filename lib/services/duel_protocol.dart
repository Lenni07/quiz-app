import 'dart:convert';
import '../models/question.dart';

/// Einfaches JSON-Nachrichtenprotokoll für das lokale Duell über WebSocket.
/// Beide Seiten spielen unabhängig voneinander denselben Fragenkatalog durch
/// und tauschen am Ende nur ihr Endergebnis aus – kein getaktetes Echtzeit-
/// Spiel, dadurch robust gegenüber unterschiedlichem Antworttempo.
sealed class DuelMessage {
  String encode();

  static DuelMessage decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    switch (json['type']) {
      case 'questions':
        return QuestionsMessage(
          (json['questions'] as List)
              .map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'score':
        return ScoreMessage(json['score'] as int, json['total'] as int);
      default:
        throw FormatException('Unbekannter Nachrichtentyp: ${json['type']}');
    }
  }
}

class QuestionsMessage extends DuelMessage {
  final List<Question> questions;

  QuestionsMessage(this.questions);

  @override
  String encode() => jsonEncode({
        'type': 'questions',
        'questions': questions.map((q) => q.toJson()).toList(),
      });
}

class ScoreMessage extends DuelMessage {
  final int score;
  final int total;

  ScoreMessage(this.score, this.total);

  @override
  String encode() => jsonEncode({'type': 'score', 'score': score, 'total': total});
}
