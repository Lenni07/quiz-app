import 'package:flutter/material.dart';
import '../models/true_false.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class TrueFalseScreen extends StatefulWidget {
  final List<TrueFalseStatement> statements;

  const TrueFalseScreen({super.key, required this.statements});

  @override
  State<TrueFalseScreen> createState() => _TrueFalseScreenState();
}

class _TrueFalseScreenState extends State<TrueFalseScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool? _selectedAnswer;

  void _selectAnswer(bool answer) {
    if (_selectedAnswer != null) return;
    final isCorrect = answer == widget.statements[_currentIndex].isTrue;
    setState(() {
      _selectedAnswer = answer;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    final isLast = _currentIndex == widget.statements.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.statements.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
    });
  }

  Color? _colorForButton(bool value, bool correctValue) {
    if (_selectedAnswer == null) return null;
    if (value == correctValue) return Colors.green;
    if (value == _selectedAnswer) return Colors.red;
    return null;
  }

  Widget _buildAnswerButton(BuildContext context, {required bool value, required IconData icon, required String label}) {
    final statement = widget.statements[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = _colorForButton(value, statement.isTrue) ?? colorScheme.primaryContainer;
    final foreground = _selectedAnswer == null ? colorScheme.onPrimaryContainer : Colors.white;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectAnswer(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(icon, size: 36, color: foreground),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statement = widget.statements[_currentIndex];
    final answered = _selectedAnswer != null;
    final isCorrect = _selectedAnswer == statement.isTrue;
    final isLast = _currentIndex == widget.statements.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wahr oder Falsch ${_currentIndex + 1} von ${widget.statements.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_currentIndex + 1) / widget.statements.length),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stufe: $_score von ${widget.statements.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
            Text(
              statement.statement,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                _buildAnswerButton(context, value: true, icon: Icons.check, label: 'Wahr'),
                const SizedBox(width: 16),
                _buildAnswerButton(context, value: false, icon: Icons.close, label: 'Falsch'),
              ],
            ),
            const SizedBox(height: 24),
            if (answered) ...[
              Text(
                isCorrect ? 'Richtig!' : 'Leider falsch.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _next,
                child: Text(isLast ? 'Fertig' : 'Weiter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
