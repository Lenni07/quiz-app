import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class RandomCardsScreen extends StatefulWidget {
  final List<Question> questions;
  final int cardCount;

  const RandomCardsScreen({super.key, required this.questions, this.cardCount = 10});

  @override
  State<RandomCardsScreen> createState() => _RandomCardsScreenState();
}

class _RandomCardsScreenState extends State<RandomCardsScreen> with SingleTickerProviderStateMixin {
  late final List<Question> _deck;
  int _currentIndex = 0;
  int _knownCount = 0;
  bool _revealed = false;
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    final shuffled = List<Question>.from(widget.questions)..shuffle(Random());
    _deck = shuffled.take(min(widget.cardCount, shuffled.length)).toList();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _reveal() {
    _flipController.forward().then((_) => setState(() => _revealed = true));
  }

  void _rate(bool known) {
    final isLast = _currentIndex == _deck.length - 1;
    final knownCount = known ? _knownCount + 1 : _knownCount;

    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: knownCount,
            total: _deck.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }

    setState(() {
      _knownCount = knownCount;
      _currentIndex++;
      _revealed = false;
      _flipController.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _deck[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = _deck.length - _currentIndex - 1;

    final frontFace = _buildFace(
      colorScheme.primaryContainer,
      Text(
        question.question,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
    final backFace = _buildFace(
      colorScheme.secondaryContainer,
      Text(
        question.options[question.correctIndex],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Random Cards (${_currentIndex + 1} von ${_deck.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _revealed ? null : _reveal,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (remaining > 0)
                        Positioned(
                          top: 12,
                          child: Opacity(
                            opacity: 0.4,
                            child: _buildFace(colorScheme.surfaceContainerHighest, const SizedBox.shrink()),
                          ),
                        ),
                      if (remaining > 1)
                        Positioned(
                          top: 22,
                          child: Opacity(
                            opacity: 0.25,
                            child: _buildFace(colorScheme.surfaceContainerHighest, const SizedBox.shrink()),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _flipController,
                        builder: (context, child) {
                          final angle = _flipController.value * pi;
                          final showFront = angle <= pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: showFront
                                ? frontFace
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi),
                                    child: backFace,
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_revealed)
              Text(
                'Tippe auf die Karte, um die Antwort zu sehen',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rate(false),
                      child: const Text('Nicht gewusst'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rate(true),
                      child: const Text('Wusste ich'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFace(Color color, Widget child) {
    return Container(
      width: 260,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      alignment: Alignment.center,
      child: child,
    );
  }
}
