import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final List<Sentence> sentences;
  final String languageCode;
  final String languageLabel;

  const FlashcardScreen({
    super.key,
    required this.sentences,
    required this.languageCode,
    required this.languageLabel,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

/// Reihenfolge beim Klicken auf die Karte:
/// germanQuestion -> translatedQuestion -> germanAnswer -> translatedAnswer
enum _Stage { germanQuestion, translatedQuestion, germanAnswer, translatedAnswer }

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _knownCount = 0;
  _Stage _stage = _Stage.germanQuestion;
  _Stage _previousStage = _Stage.germanQuestion;
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  bool get _revealed => _stage == _Stage.translatedAnswer;

  void _advanceStage() {
    if (_revealed) return;
    setState(() {
      _previousStage = _stage;
      _stage = _Stage.values[_stage.index + 1];
    });
    _flipController.forward(from: 0);
  }

  void _rate(bool known) {
    final isLast = _currentIndex == widget.sentences.length - 1;
    final knownCount = known ? _knownCount + 1 : _knownCount;

    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: knownCount,
            total: widget.sentences.length,
            formatId: 'karteikarten',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }

    setState(() {
      _knownCount = knownCount;
      _currentIndex++;
      _stage = _Stage.germanQuestion;
      _previousStage = _Stage.germanQuestion;
      _flipController.value = 0;
    });
  }

  Widget _buildCardFace(_Stage stage, Sentence sentence, ColorScheme colorScheme) {
    final translation = sentence.translations[widget.languageCode];
    late final String label;
    late final String text;
    late final Color color;

    switch (stage) {
      case _Stage.germanQuestion:
        label = 'Frage (Deutsch)';
        text = sentence.question;
        color = colorScheme.primaryContainer;
      case _Stage.translatedQuestion:
        label = 'Frage (${widget.languageLabel})';
        text = translation?.question ?? '–';
        color = colorScheme.secondaryContainer;
      case _Stage.germanAnswer:
        label = 'Musterantwort (Deutsch)';
        text = sentence.correctAnswer;
        color = colorScheme.primaryContainer;
      case _Stage.translatedAnswer:
        label = 'Musterantwort (${widget.languageLabel})';
        text = translation?.answer ?? '–';
        color = colorScheme.secondaryContainer;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentences[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Karteikarten ${_currentIndex + 1} von ${widget.sentences.length}'),
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
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _revealed ? null : _advanceStage,
                  child: AnimatedBuilder(
                    animation: _flipController,
                    builder: (context, child) {
                      final angle = _flipController.value * pi;
                      final showPrevious = angle <= pi / 2;
                      final stageToShow = showPrevious ? _previousStage : _stage;
                      final face = _buildCardFace(stageToShow, sentence, colorScheme);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showPrevious
                            ? face
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: face,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_revealed)
              Text(
                'Tippe auf die Karte, um weiterzugehen',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rate(false),
                      child: const Text('Muss ich üben'),
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
}
