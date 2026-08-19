import 'package:flutter/material.dart';

class DuelResultScreen extends StatelessWidget {
  final int myScore;
  final int opponentScore;
  final int total;

  const DuelResultScreen({
    super.key,
    required this.myScore,
    required this.opponentScore,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String resultText;
    final IconData icon;
    final Color color;

    if (myScore > opponentScore) {
      resultText = 'Du hast gewonnen! 🎉';
      icon = Icons.emoji_events;
      color = Colors.amber[700]!;
    } else if (myScore < opponentScore) {
      resultText = 'Diesmal hat dein Gegner gewonnen.';
      icon = Icons.school;
      color = colorScheme.primary;
    } else {
      resultText = 'Unentschieden!';
      icon = Icons.handshake;
      color = colorScheme.primary;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 90, color: color),
              const SizedBox(height: 24),
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _ScoreRow(label: 'Du', score: myScore, total: total),
              const SizedBox(height: 12),
              _ScoreRow(label: 'Gegner', score: opponentScore, total: total),
              const SizedBox(height: 48),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Zurück zum Start'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final int total;

  const _ScoreRow({required this.label, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $score von $total',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
  }
}
