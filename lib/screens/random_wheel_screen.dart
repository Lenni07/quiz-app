import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

const int _segmentCount = 8;
const List<Color> _segmentColors = [
  Colors.redAccent,
  Colors.orangeAccent,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blueAccent,
  Colors.indigo,
  Colors.purpleAccent,
];

class RandomWheelScreen extends StatefulWidget {
  final List<Question> questions;
  final int roundCount;

  const RandomWheelScreen({super.key, required this.questions, this.roundCount = 8});

  @override
  State<RandomWheelScreen> createState() => _RandomWheelScreenState();
}

class _RandomWheelScreenState extends State<RandomWheelScreen> with SingleTickerProviderStateMixin {
  late final List<Question> _roundQuestions;
  late final AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;

  int _round = 0;
  bool _spinning = false;
  bool _revealed = false;
  int? _selectedIndex;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    final shuffled = List<Question>.from(widget.questions)..shuffle(Random());
    _roundQuestions = shuffled.take(min(widget.roundCount, shuffled.length)).toList();
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _revealed) return;
    final random = Random();
    final targetSegment = random.nextInt(_segmentCount);
    final segmentAngle = 2 * pi / _segmentCount;
    final extraSpins = 4 + random.nextInt(3);
    final targetAngle =
        _currentAngle + extraSpins * 2 * pi + (2 * pi - (targetSegment * segmentAngle + segmentAngle / 2));

    _spinAnimation = Tween<double>(begin: _currentAngle, end: targetAngle)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_spinController)
      ..addListener(() => setState(() {}));

    setState(() => _spinning = true);
    _spinController
      ..reset()
      ..forward().then((_) {
        _currentAngle = targetAngle % (2 * pi);
        setState(() {
          _spinning = false;
          _revealed = true;
        });
      });
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final isCorrect = index == _roundQuestions[_round].correctIndex;
    setState(() {
      _selectedIndex = index;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    final isLast = _round == _roundQuestions.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: _roundQuestions.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _round++;
      _revealed = false;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Random Wheel ${_round + 1} von ${_roundQuestions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stufe: $_score von ${_roundQuestions.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            if (!_revealed) _buildWheel() else Expanded(child: _buildQuestion(context, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    final angle = _spinning ? _spinAnimation.value : _currentAngle;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: angle,
                    child: CustomPaint(
                      size: const Size(240, 240),
                      painter: _WheelPainter(),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 48, color: Colors.black87),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _spinning ? null : _spin,
              child: Text(_spinning ? 'Dreht ...' : 'Drehen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, ColorScheme colorScheme) {
    final question = _roundQuestions[_round];
    final answered = _selectedIndex != null;
    final isLast = _round == _roundQuestions.length - 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.question,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < question.options.length; i++) ...[
            _buildOption(context, i, question),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          if (answered)
            Center(
              child: ElevatedButton(
                onPressed: _next,
                child: Text(isLast ? 'Fertig' : 'Nächste Runde'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, Question question) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.primaryContainer;
    if (_selectedIndex != null) {
      if (index == question.correctIndex) {
        backgroundColor = Colors.green;
      } else if (index == _selectedIndex) {
        backgroundColor = Colors.red;
      }
    }
    final textColor = _selectedIndex == null ? colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
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
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / _segmentCount;
    for (var i = 0; i < _segmentCount; i++) {
      final paint = Paint()..color = _segmentColors[i % _segmentColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle,
        segmentAngle,
        true,
        paint,
      );
    }
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
