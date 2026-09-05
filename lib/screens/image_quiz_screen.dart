import 'package:flutter/material.dart';
import '../models/image_quiz.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';
import 'result_screen.dart';

const Map<String, IconData> _imageQuizIcons = {
  'restaurant': Icons.restaurant,
  'local_hospital': Icons.local_hospital,
  'cleaning_services': Icons.cleaning_services,
  'luggage': Icons.luggage,
  'anchor': Icons.anchor,
  'directions_boat': Icons.directions_boat,
  'menu_book': Icons.menu_book,
  'bed': Icons.bed,
  'wb_sunny': Icons.wb_sunny,
  'waves': Icons.waves,
};

class ImageQuizScreen extends StatefulWidget {
  final List<ImageQuizItem> items;

  const ImageQuizScreen({super.key, required this.items});

  @override
  State<ImageQuizScreen> createState() => _ImageQuizScreenState();
}

class _ImageQuizScreenState extends State<ImageQuizScreen> with AnswerFeedbackMixin {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final isCorrect = index == widget.items[_currentIndex].correctIndex;
    setState(() {
      _selectedIndex = index;
      if (isCorrect) _score++;
    });
    if (isCorrect) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _next() {
    final isLast = _currentIndex == widget.items.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.items.length,
            formatId: 'bild-quiz',
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

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_currentIndex];
    final isLast = _currentIndex == widget.items.length - 1;
    final colorScheme = Theme.of(context).colorScheme;
    final answered = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(title: Text('Bild-Quiz ${_currentIndex + 1} von ${widget.items.length}')),
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
                    tween: Tween(begin: 0, end: (_currentIndex + 1) / widget.items.length),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Stufe: ', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    CountUpNumber(_score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                    Text(' von ${widget.items.length}', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Welches Wort passt zu diesem Symbol?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _imageQuizIcons[item.icon] ?? Icons.help_outline,
                      size: 80,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                wrapWithShake(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < item.options.length; i++) ...[
                        _buildOption(context, i, item),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (answered) ...[
                  Center(
                    child: Text(
                      _selectedIndex == item.correctIndex
                          ? 'Richtig!'
                          : 'Leider falsch. Richtig wäre: "${item.options[item.correctIndex]}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == item.correctIndex ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Fertig' : 'Nächste Frage'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...feedbackOverlayLayers(),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, ImageQuizItem item) {
    final backgroundColor =
        _colorForOption(index, item.correctIndex) ?? Theme.of(context).colorScheme.primaryContainer;
    final textColor = _selectedIndex == null ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white;

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
              item.options[index],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
