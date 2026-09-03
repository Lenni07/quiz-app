import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import '../widgets/firework_particle.dart';
import 'result_screen.dart';

/// Hörverständnis-Format (siehe ROADMAP_QuizApp.md Abschnitt 18c): ein
/// deutscher Satz wird per Text-to-Speech vorgelesen, der Spieler erkennt
/// die englische Bedeutung aus vier Optionen. Nutzt dieselben
/// sentences.json-Daten wie "Konversation üben", aber die englischen
/// Übersetzungen als Antwortoptionen statt der deutschen Erwiderung - so
/// entsteht kein doppeltes Format, sondern eine eigene Hörverständnis-Übung.
class ListeningScreen extends StatefulWidget {
  final List<Sentence> sentences;
  final String formatId;

  const ListeningScreen({super.key, required this.sentences, this.formatId = 'hoerverstehen'});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _RoundData {
  final Sentence sentence;
  final List<String> options;
  final int correctIndex;

  _RoundData({required this.sentence, required this.options, required this.correctIndex});
}

class _ListeningScreenState extends State<ListeningScreen> {
  late final FlutterTts _tts;
  late final List<_RoundData> _rounds;
  int _currentIndex = 0;
  int? _selectedIndex;
  int _score = 0;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('de-DE');
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 900));
    _rounds = _buildRounds(widget.sentences);
    _speakCurrent();
  }

  List<_RoundData> _buildRounds(List<Sentence> sentences) {
    final random = Random();
    return sentences.map((sentence) {
      final correctMeaning = sentence.translations['en']?.question ?? sentence.question;
      final otherMeanings = sentences
          .where((s) => s != sentence)
          .map((s) => s.translations['en']?.question)
          .whereType<String>()
          .where((meaning) => meaning != correctMeaning)
          .toSet()
          .toList()
        ..shuffle(random);
      final options = [correctMeaning, ...otherMeanings.take(3)]..shuffle(random);
      return _RoundData(sentence: sentence, options: options, correctIndex: options.indexOf(correctMeaning));
    }).toList();
  }

  Future<void> _speakCurrent() async {
    await _tts.stop();
    await _tts.speak(_rounds[_currentIndex].sentence.question);
  }

  @override
  void dispose() {
    _tts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final round = _rounds[_currentIndex];
    final isCorrect = index == round.correctIndex;
    setState(() {
      _selectedIndex = index;
      if (isCorrect) {
        _score++;
        _confettiController.play();
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
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
    _speakCurrent();
  }

  Color? _colorForOption(int index, int correctIndex) {
    if (_selectedIndex == null) return null;
    if (index == correctIndex) return Colors.green;
    if (index == _selectedIndex) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentIndex];
    final answered = _selectedIndex != null;
    final isCorrect = _selectedIndex == round.correctIndex;
    final isLast = _currentIndex == _rounds.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Hörverständnis ${_currentIndex + 1} von ${_rounds.length}')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: (_currentIndex + 1) / _rounds.length, minHeight: 8),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      IconButton.filled(
                        iconSize: 56,
                        padding: const EdgeInsets.all(20),
                        onPressed: _speakCurrent,
                        icon: const Icon(Icons.volume_up),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Antippen zum (erneuten) Anhören',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Was bedeutet der Satz?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < round.options.length; i++) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _colorForOption(i, round.correctIndex) ?? colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectAnswer(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Text(
                            round.options[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedIndex == null ? colorScheme.onPrimaryContainer : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (answered) ...[
                  Text(
                    isCorrect ? '🎉 Richtig!' : 'Leider falsch.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Fertig' : 'Nächster Satz'),
                  ),
                ],
              ],
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
