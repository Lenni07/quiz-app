import 'dart:math';
import 'package:flutter/material.dart';
import '../models/number_word.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class _Round {
  final NumberWord left;
  final NumberWord right;

  _Round({required this.left, required this.right});
}

class HigherLowerScreen extends StatefulWidget {
  final List<NumberWord> words;
  final int roundCount;

  const HigherLowerScreen({super.key, required this.words, this.roundCount = 10});

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  late final List<_Round> _rounds;
  int _currentIndex = 0;
  int _score = 0;
  bool? _pickedLeft;

  @override
  void initState() {
    super.initState();
    _rounds = _generateRounds();
  }

  List<_Round> _generateRounds() {
    final random = Random();
    return List.generate(widget.roundCount, (_) {
      final shuffled = List<NumberWord>.from(widget.words)..shuffle(random);
      var left = shuffled[0];
      var right = shuffled[1];
      if (left.value == right.value && shuffled.length > 2) {
        right = shuffled[2];
      }
      return _Round(left: left, right: right);
    });
  }

  void _choose(bool pickedLeft) {
    if (_pickedLeft != null) return;
    final round = _rounds[_currentIndex];
    final isCorrect = pickedLeft ? round.left.value > round.right.value : round.right.value > round.left.value;
    setState(() {
      _pickedLeft = pickedLeft;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    final isLast = _currentIndex == _rounds.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: _rounds.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _pickedLeft = null;
    });
  }

  Color? _colorFor(NumberWord word, NumberWord other, bool isLeftSide) {
    if (_pickedLeft == null) return null;
    if (word.value > other.value) return Colors.green;
    final wasPicked = isLeftSide ? _pickedLeft == true : _pickedLeft == false;
    if (wasPicked) return Colors.red;
    return null;
  }

  Widget _buildCard(BuildContext context, NumberWord word, NumberWord other, {required bool isLeftSide}) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = _colorFor(word, other, isLeftSide) ?? colorScheme.primaryContainer;
    final foreground = _pickedLeft == null ? colorScheme.onPrimaryContainer : Colors.white;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(16)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _choose(isLeftSide),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
              child: Text(
                word.word,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentIndex];
    final isLast = _currentIndex == _rounds.length - 1;
    final colorScheme = Theme.of(context).colorScheme;
    final answered = _pickedLeft != null;

    return Scaffold(
      appBar: AppBar(title: Text('Higher or Lower ${_currentIndex + 1} von ${_rounds.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_currentIndex + 1) / _rounds.length),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stufe: $_score von ${_rounds.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              'Welches Zahlwort ist größer?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildCard(context, round.left, round.right, isLeftSide: true),
                const SizedBox(width: 16),
                _buildCard(context, round.right, round.left, isLeftSide: false),
              ],
            ),
            const SizedBox(height: 24),
            if (answered) ...[
              Center(
                child: Text(
                  '${round.left.word} = ${round.left.value}, ${round.right.word} = ${round.right.value}',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Fertig' : 'Nächste Runde'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
