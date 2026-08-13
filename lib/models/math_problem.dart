import 'dart:math';

class MathProblem {
  final String question;
  final int correctAnswer;

  MathProblem({required this.question, required this.correctAnswer});
}

List<MathProblem> generateMathProblems(int count) {
  final random = Random();
  return List.generate(count, (_) {
    final operator = ['+', '-', '×'][random.nextInt(3)];
    switch (operator) {
      case '+':
        final a = random.nextInt(50) + 1;
        final b = random.nextInt(50) + 1;
        return MathProblem(question: '$a + $b', correctAnswer: a + b);
      case '-':
        final a = random.nextInt(50) + 10;
        final b = random.nextInt(a);
        return MathProblem(question: '$a - $b', correctAnswer: a - b);
      default:
        final a = random.nextInt(11) + 2;
        final b = random.nextInt(11) + 2;
        return MathProblem(question: '$a × $b', correctAnswer: a * b);
    }
  });
}
