import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/sound_effects.dart';
import '../models/question.dart';
import '../services/question_mastery_service.dart';
import '../utils/current_uid.dart';
import '../utils/page_transitions.dart';
import '../widgets/firework_particle.dart';
import '../widgets/shake.dart';
import 'result_screen.dart';

class QuestionScreen extends StatefulWidget {
  final List<Question> questions;
  final String formatId;

  const QuestionScreen({super.key, required this.questions, required this.formatId});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _currentIndex = 0;
  int? _selectedIndex;
  int _score = 0;
  int _streak = 0;
  bool _showFlash = false;
  int _shakeTrigger = 0;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final question = widget.questions[_currentIndex];
    final isCorrect = index == question.correctIndex;
    // Nur echte Katalogfragen fließen in die Fortschrittsanzeige ein, nicht
    // die aus Sentence-Daten synthetisierten Fragen von "Konversation üben".
    if (widget.formatId == 'allgemeinwissen-quiz') {
      QuestionMasteryService().recordAnswer(question, wasCorrect: isCorrect, uid: currentUid());
    }
    setState(() {
      _selectedIndex = index;
      if (isCorrect) {
        _score++;
        _streak++;
        _showFlash = true;
        _confettiController.play();
        HapticFeedback.heavyImpact();
        SoundEffects.instance.playCorrect();
      } else {
        _streak = 0;
        _shakeTrigger++;
        HapticFeedback.mediumImpact();
        SoundEffects.instance.playWrong();
      }
    });
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _showFlash = false);
      });
    }
  }

  void _nextQuestion() {
    final isLastQuestion = _currentIndex == widget.questions.length - 1;
    if (isLastQuestion) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.questions.length,
            formatId: widget.formatId,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
    });
  }

  Color? _colorForOption(int index, int correctIndex) {
    if (_selectedIndex == null) return null;
    if (index == correctIndex) return Colors.green;
    if (index == _selectedIndex) return Colors.red;
    return null;
  }

  Widget _buildOptionButton(BuildContext context, int index, Question question) {
    final backgroundColor =
        _colorForOption(index, question.correctIndex) ?? Theme.of(context).colorScheme.primaryContainer;
    final textColor = _selectedIndex == null
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
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

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final answered = _selectedIndex != null;
    final isCorrect = _selectedIndex == question.correctIndex;
    final isLastQuestion = _currentIndex == widget.questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Frage ${_currentIndex + 1} von ${widget.questions.length}')),
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
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stufe: $_score von ${widget.questions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                        child: child,
                      ),
                      child: _streak >= 2
                          ? Text(
                              '${'🔥' * min(_streak - 1, 3)} $_streak in Folge!',
                              key: ValueKey(_streak),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-streak')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ShakeOnTrigger(
                    trigger: _shakeTrigger,
                    child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.15, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offsetAnimation, child: child),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(_currentIndex),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            question.question,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          for (var i = 0; i < question.options.length; i++) ...[
                            _buildOptionButton(context, i, question),
                            const SizedBox(height: 12),
                          ],
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: answered
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: 1),
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.elasticOut,
                                          builder: (context, scale, child) => Transform.scale(
                                            scale: scale,
                                            child: child,
                                          ),
                                          child: Text(
                                            isCorrect ? '🎉 Richtig!' : 'Leider falsch.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: isCorrect ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton(
                                          onPressed: _nextQuestion,
                                          child: Text(isLastQuestion ? 'Fertig' : 'Nächste Frage'),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _showFlash ? 1 : 0,
              child: Container(color: Colors.green.withValues(alpha: 0.25)),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 35,
              maxBlastForce: 30,
              minBlastForce: 12,
              gravity: 0.15,
              minimumSize: const Size(5, 5),
              maximumSize: const Size(11, 11),
              colors: fireworkColors,
              createParticlePath: drawFireworkSpark,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
