import 'dart:math';
import 'package:flutter/material.dart';
import '../models/math_problem.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class MathGeneratorScreen extends StatefulWidget {
  final int problemCount;

  const MathGeneratorScreen({super.key, this.problemCount = 10});

  @override
  State<MathGeneratorScreen> createState() => _MathGeneratorScreenState();
}

class _MathGeneratorScreenState extends State<MathGeneratorScreen> {
  late final List<MathProblem> _problems;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _problems = generateMathProblems(widget.problemCount);
    _options = _buildOptions(_problems[_currentIndex].correctAnswer);
  }

  List<int> _buildOptions(int correctAnswer) {
    final random = Random();
    final options = <int>{correctAnswer};
    while (options.length < 4) {
      final offset = random.nextInt(10) + 1;
      final candidate = random.nextBool() ? correctAnswer + offset : max(0, correctAnswer - offset);
      options.add(candidate);
    }
    return options.toList()..shuffle(random);
  }

  void _selectAnswer(int value) {
    if (_selectedAnswer != null) return;
    final isCorrect = value == _problems[_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = value;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    final isLast = _currentIndex == _problems.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: _problems.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _options = _buildOptions(_problems[_currentIndex].correctAnswer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problems[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final answered = _selectedAnswer != null;
    final isLast = _currentIndex == _problems.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Rechnen üben ${_currentIndex + 1} von ${_problems.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_currentIndex + 1) / _problems.length),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stufe: $_score von ${_problems.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
            Text(
              '${problem.question} = ?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            for (var value in _options) ...[
              _buildOption(context, value, problem.correctAnswer),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            if (answered)
              Center(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Fertig' : 'Nächste Aufgabe'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int value, int correctAnswer) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.primaryContainer;
    if (_selectedAnswer != null) {
      if (value == correctAnswer) {
        backgroundColor = Colors.green;
      } else if (value == _selectedAnswer) {
        backgroundColor = Colors.red;
      }
    }
    final textColor = _selectedAnswer == null ? colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectAnswer(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
