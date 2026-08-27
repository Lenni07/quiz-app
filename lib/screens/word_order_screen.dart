import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class WordOrderScreen extends StatefulWidget {
  final List<Sentence> sentences;

  const WordOrderScreen({super.key, required this.sentences});

  @override
  State<WordOrderScreen> createState() => _WordOrderScreenState();
}

class _WordOrderScreenState extends State<WordOrderScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _isCorrect = false;
  late List<String> _pool;
  late List<String> _placed;

  @override
  void initState() {
    super.initState();
    _setUpSentence();
  }

  void _setUpSentence() {
    final words = widget.sentences[_currentIndex].words;
    _pool = List<String>.from(words)..shuffle(Random());
    _placed = [];
  }

  void _placeWord(int poolIndex) {
    if (_answered) return;
    setState(() {
      _placed.add(_pool.removeAt(poolIndex));
      if (_placed.length == widget.sentences[_currentIndex].words.length) {
        _answered = true;
        _isCorrect = _wordsMatch(_placed, widget.sentences[_currentIndex].words);
        if (_isCorrect) _score++;
      }
    });
  }

  void _removePlacedWord(int placedIndex) {
    if (_answered) return;
    setState(() {
      _pool.add(_placed.removeAt(placedIndex));
    });
  }

  bool _wordsMatch(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
            formatId: 'richtige-reihenfolge',
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
      _setUpSentence();
    });
  }

  Widget _buildChip(String word, {required Color color, required VoidCallback? onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentences[_currentIndex];
    final isLast = _currentIndex == widget.sentences.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Richtige Reihenfolge ${_currentIndex + 1} von ${widget.sentences.length}'),
      ),
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
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              sentence.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text('Deine Antwort:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _placed.length; i++)
                    _buildChip(
                      _placed[i],
                      color: _answered
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : colorScheme.secondaryContainer,
                      onTap: () => _removePlacedWord(i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Verfügbare Wörter:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _pool.length; i++)
                  _buildChip(
                    _pool[i],
                    color: colorScheme.primaryContainer,
                    onTap: () => _placeWord(i),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_answered) ...[
              Text(
                _isCorrect ? 'Richtig!' : 'Leider falsch. Richtig wäre: "${sentence.correctAnswer}"',
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
