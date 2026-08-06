import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class FillBlankScreen extends StatefulWidget {
  final List<Sentence> sentences;

  const FillBlankScreen({super.key, required this.sentences});

  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> {
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
    setState(() {
      _answered = true;
      _isCorrect = input == correctWord;
      if (_isCorrect) _score++;
    });
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

    return Scaffold(
      appBar: AppBar(title: Text('Lückentext ${_currentIndex + 1} von ${widget.sentences.length}')),
      body: Padding(
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
            Text(
              'Stufe: $_score von ${widget.sentences.length}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              sentence.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              sentence.blankedSentence,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    );
  }
}
