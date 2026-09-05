import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_mastery_service.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';

/// Beide Duell-Teilnehmer spielen denselben Fragensatz unabhängig
/// voneinander durch; am Ende wird das Ergebnis per `Navigator.pop`
/// als Punktzahl zurückgegeben.
class DuelPlayScreen extends StatefulWidget {
  final List<Question> questions;

  const DuelPlayScreen({super.key, required this.questions});

  @override
  State<DuelPlayScreen> createState() => _DuelPlayScreenState();
}

class _DuelPlayScreenState extends State<DuelPlayScreen> with AnswerFeedbackMixin {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final question = widget.questions[_currentIndex];
    final isCorrect = index == question.correctIndex;
    QuestionMasteryService().recordAnswer(question, wasCorrect: isCorrect);
    setState(() {
      _selectedIndex = index;
      if (isCorrect) _score++;
    });
    if (isCorrect) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _next() {
    final isLast = _currentIndex == widget.questions.length - 1;
    if (isLast) {
      Navigator.pop(context, _score);
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final answered = _selectedIndex != null;
    final isLast = _currentIndex == widget.questions.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Duell-Frage ${_currentIndex + 1} von ${widget.questions.length}'),
        automaticallyImplyLeading: false,
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
                if (answered) ...[
                  Center(
                    child: Text(
                      _selectedIndex == question.correctIndex
                          ? 'Richtig!'
                          : 'Leider falsch. Richtig wäre: "${question.options[question.correctIndex]}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == question.correctIndex ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Fertig' : 'Nächste Frage'),
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.primaryContainer;
    if (_selectedIndex != null) {
      if (index == question.correctIndex) {
        backgroundColor = Colors.green;
      } else if (index == _selectedIndex) {
        backgroundColor = Colors.red;
      }
    }
    final textColor = _selectedIndex == null ? colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectAnswer(index),
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
