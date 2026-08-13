import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

const List<Alignment> _balloonPositions = [
  Alignment(-0.6, -0.4),
  Alignment(0.55, -0.55),
  Alignment(-0.55, 0.35),
  Alignment(0.6, 0.45),
];

const List<Color> _balloonColors = [
  Colors.redAccent,
  Colors.blueAccent,
  Colors.orangeAccent,
  Colors.teal,
];

class BalloonPopScreen extends StatefulWidget {
  final List<Question> questions;
  final Duration timeLimit;

  const BalloonPopScreen({super.key, required this.questions, this.timeLimit = const Duration(seconds: 6)});

  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonPopScreenState extends State<BalloonPopScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;

  late final AnimationController _bobController;
  late final AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _timerController = AnimationController(vsync: this, duration: widget.timeLimit)
      ..addStatusListener(_onTimerStatus)
      ..forward();
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_answered) {
      _handleAnswer(null);
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _handleAnswer(int? index) {
    if (_answered) return;
    final question = widget.questions[_currentIndex];
    final isCorrect = index == question.correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
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
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
      _timerController
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Balloon Pop ${_currentIndex + 1} von ${widget.questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1 - _timerController.value,
                  minHeight: 8,
                  color: _timerController.value > 0.75 ? Colors.red : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stufe: $_score von ${widget.questions.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    _buildBalloon(context, i, question),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalloon(BuildContext context, int index, Question question) {
    final alignment = _balloonPositions[index % _balloonPositions.length];
    final baseColor = _balloonColors[index % _balloonColors.length];
    final isCorrect = index == question.correctIndex;
    final isSelected = index == _selectedIndex;

    Color color = baseColor;
    if (_answered) {
      if (isCorrect) {
        color = Colors.green;
      } else if (isSelected) {
        color = Colors.red;
      } else {
        color = baseColor.withValues(alpha: 0.3);
      }
    }

    return AnimatedBuilder(
      animation: _bobController,
      builder: (context, child) {
        final phase = index * pi / 2;
        final dy = sin(_bobController.value * 2 * pi + phase) * 10;
        return Align(
          alignment: alignment,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _handleAnswer(index),
        child: AnimatedScale(
          scale: _answered && isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 130,
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(65),
                topRight: Radius.circular(65),
                bottomLeft: Radius.circular(65),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: Text(
              question.options[index],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
