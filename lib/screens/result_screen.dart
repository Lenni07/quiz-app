import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../widgets/firework_particle.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final VoidCallback onPlayAgain;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.onPlayAgain,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final List<ConfettiController> _fireworkControllers;
  late final List<Alignment> _fireworkPositions;

  bool get _isGoodResult => widget.score > widget.total / 2;

  @override
  void initState() {
    super.initState();
    _fireworkPositions = const [
      Alignment(-0.5, -0.4),
      Alignment(0.4, -0.6),
      Alignment(-0.2, -0.2),
    ];
    _fireworkControllers = List.generate(
      _fireworkPositions.length,
      (_) => ConfettiController(duration: const Duration(milliseconds: 700)),
    );
    if (_isGoodResult) {
      _launchFireworks();
    }
  }

  void _launchFireworks() async {
    for (var i = 0; i < _fireworkControllers.length; i++) {
      if (!mounted) return;
      _fireworkControllers[i].play();
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  void dispose() {
    for (final controller in _fireworkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Icon(
                      _isGoodResult ? Icons.emoji_events : Icons.school,
                      size: 90,
                      color: _isGoodResult ? Colors.amber[700] : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ergebnis',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.score),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      '$value von ${widget.total} richtig',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: widget.onPlayAgain,
                      child: const Text('Nochmal spielen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < _fireworkPositions.length; i++)
            Align(
              alignment: _fireworkPositions[i],
              child: ConfettiWidget(
                confettiController: _fireworkControllers[i],
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                maxBlastForce: 28,
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
