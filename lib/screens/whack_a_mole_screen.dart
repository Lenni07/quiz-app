import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

const int _holeCount = 6;
const Duration _visibleDuration = Duration(milliseconds: 950);
const Duration _gapDuration = Duration(milliseconds: 250);

class WhackAMoleScreen extends StatefulWidget {
  final List<Question> questions;

  const WhackAMoleScreen({super.key, required this.questions});

  @override
  State<WhackAMoleScreen> createState() => _WhackAMoleScreenState();
}

class _WhackAMoleScreenState extends State<WhackAMoleScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int _sessionToken = 0;
  late List<int> _queue;
  int? _activeOptionIndex;
  int? _activeHole;
  bool _answered = false;
  bool _lastCorrect = false;

  @override
  void initState() {
    super.initState();
    _startQuestion();
  }

  void _startQuestion() {
    final options = List.generate(widget.questions[_currentIndex].options.length, (i) => i)..shuffle(Random());
    _queue = options;
    _answered = false;
    _activeOptionIndex = null;
    _activeHole = null;
    _sessionToken++;
    _runQueue(_sessionToken);
  }

  Future<void> _runQueue(int token) async {
    while (_queue.isNotEmpty) {
      if (!mounted || token != _sessionToken || _answered) return;
      final optionIndex = _queue.removeAt(0);
      final hole = Random().nextInt(_holeCount);
      setState(() {
        _activeOptionIndex = optionIndex;
        _activeHole = hole;
      });
      await Future.delayed(_visibleDuration);
      if (!mounted || token != _sessionToken || _answered) return;
      setState(() {
        _activeOptionIndex = null;
        _activeHole = null;
      });
      await Future.delayed(_gapDuration);
    }
    if (!mounted || token != _sessionToken || _answered) return;
    _resolve(false);
  }

  void _whack(int hole) {
    if (_answered) return;
    if (hole != _activeHole || _activeOptionIndex == null) return;
    final isCorrect = _activeOptionIndex == widget.questions[_currentIndex].correctIndex;
    _resolve(isCorrect);
  }

  void _resolve(bool isCorrect) {
    setState(() {
      _answered = true;
      _lastCorrect = isCorrect;
      if (isCorrect) _score++;
    });
    Future.delayed(const Duration(milliseconds: 700), _next);
  }

  void _next() {
    if (!mounted) return;
    final isLast = _currentIndex == widget.questions.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.questions.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() => _currentIndex++);
    _startQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Whack-a-Mole ${_currentIndex + 1} von ${widget.questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stufe: $_score von ${widget.questions.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            Text(
              'Schlag zu, sobald "${question.options[question.correctIndex]}" auftaucht!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: _holeCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, hole) {
                  final showsMole = _activeHole == hole && _activeOptionIndex != null;
                  return Material(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(60),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(60),
                      onTap: () => _whack(hole),
                      child: Center(
                        child: AnimatedScale(
                          scale: showsMole ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            width: 110,
                            height: 70,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: showsMole
                                ? Text(
                                    question.options[_activeOptionIndex!],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_answered)
              Center(
                child: Text(
                  _lastCorrect ? 'Richtig!' : 'Leider verpasst.',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
