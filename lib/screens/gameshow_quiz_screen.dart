import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';
import 'result_screen.dart';

/// Wie das normale Quiz, aber mit Spannungsmoment: Nach der Auswahl wird die
/// Antwort erst "gesperrt" und nach einer kurzen Verzögerung aufgedeckt.
class GameshowQuizScreen extends StatefulWidget {
  final List<Question> questions;

  const GameshowQuizScreen({super.key, required this.questions});

  @override
  State<GameshowQuizScreen> createState() => _GameshowQuizScreenState();
}

class _GameshowQuizScreenState extends State<GameshowQuizScreen> with AnswerFeedbackMixin {
  int _currentIndex = 0;
  int _score = 0;
  int? _lockedIndex;
  bool _revealed = false;

  void _lockInAnswer(int index) {
    if (_lockedIndex != null) return;
    setState(() => _lockedIndex = index);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      final isCorrect = index == widget.questions[_currentIndex].correctIndex;
      setState(() {
        _revealed = true;
        if (isCorrect) _score++;
      });
      if (isCorrect) {
        triggerCorrectFeedback();
      } else {
        triggerWrongFeedback();
      }
    });
  }

  void _next() {
    final isLast = _currentIndex == widget.questions.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.questions.length,
            formatId: 'gameshow-quiz',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _lockedIndex = null;
      _revealed = false;
    });
  }

  Color? _colorForOption(int index, int correctIndex) {
    if (_lockedIndex == null) return null;
    if (!_revealed) return index == _lockedIndex ? Colors.amber : null;
    if (index == correctIndex) return Colors.green;
    if (index == _lockedIndex) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final isLast = _currentIndex == widget.questions.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gameshow-Quiz ${_currentIndex + 1} von ${widget.questions.length}'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (_currentIndex + 1) / widget.questions.length),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Stufe: ', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    CountUpNumber(_score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    Text(' von ${widget.questions.length}', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                wrapWithShake(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < question.options.length; i++) ...[
                        _buildOption(context, i, question),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_lockedIndex != null && !_revealed)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '🥁 Antwort wird geprüft ...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (_revealed) ...[
                  Center(
                    child: Text(
                      _lockedIndex == question.correctIndex
                          ? '🎉 Richtig!'
                          : 'Leider falsch. Richtig wäre: "${question.options[question.correctIndex]}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _lockedIndex == question.correctIndex ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Fertig' : 'Nächste Frage'),
                  ),
                ],
              ],
            ),
          ),
          ...feedbackOverlayLayers(),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, Question question) {
    final backgroundColor =
        _colorForOption(index, question.correctIndex) ?? Theme.of(context).colorScheme.primaryContainer;
    final textColor = _lockedIndex == null ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _lockInAnswer(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Text(
              question.options[index],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
