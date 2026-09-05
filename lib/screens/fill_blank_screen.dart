import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';
import 'result_screen.dart';

class FillBlankScreen extends StatefulWidget {
  final List<Sentence> sentences;

  const FillBlankScreen({super.key, required this.sentences});

  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> with AnswerFeedbackMixin {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _isCorrect = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_answered || _controller.text.trim().isEmpty) return;
    final sentence = widget.sentences[_currentIndex];
    final input = _controller.text.trim().toLowerCase();
    final correctWord = sentence.blankWord.toLowerCase();
    late final bool isCorrect;
    setState(() {
      _answered = true;
      _isCorrect = input == correctWord;
      isCorrect = _isCorrect;
      if (_isCorrect) _score++;
    });
    if (isCorrect) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _next() {
    final isLast = _currentIndex == widget.sentences.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.sentences.length,
            formatId: 'lueckentext',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _answered = false;
      _isCorrect = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentences[_currentIndex];
    final isLast = _currentIndex == widget.sentences.length - 1;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Lückentext ${_currentIndex + 1} von ${widget.sentences.length}')),
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
                    tween: Tween(begin: 0, end: (_currentIndex + 1) / widget.sentences.length),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Stufe: ', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    CountUpNumber(_score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    Text(' von ${widget.sentences.length}', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  sentence.question,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                wrapWithShake(
                  Text(
                    sentence.blankedSentence,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  enabled: !_answered,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Fehlendes Wort eingeben',
                  ),
                  onSubmitted: (_) => _checkAnswer(),
                ),
                const SizedBox(height: 20),
                if (!_answered)
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    child: const Text('Prüfen'),
                  ),
                if (_answered) ...[
                  Text(
                    _isCorrect ? 'Richtig!' : 'Leider falsch. Richtig wäre: "${sentence.blankWord}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green : Colors.red,
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
          ...feedbackOverlayLayers(),
        ],
      ),
    );
  }
}
