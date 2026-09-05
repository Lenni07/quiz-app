import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_mastery_service.dart';
import '../utils/current_uid.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import 'result_screen.dart';

class OpenBoxScreen extends StatefulWidget {
  final List<Question> questions;

  const OpenBoxScreen({super.key, required this.questions});

  @override
  State<OpenBoxScreen> createState() => _OpenBoxScreenState();
}

class _OpenBoxScreenState extends State<OpenBoxScreen> with AnswerFeedbackMixin {
  final Set<int> _openedBoxes = {};
  int _score = 0;
  int? _activeBox;
  int? _selectedOption;

  void _openBox(int index) {
    if (_openedBoxes.contains(index)) return;
    setState(() {
      _activeBox = index;
      _selectedOption = null;
    });
  }

  void _selectOption(int optionIndex) {
    if (_selectedOption != null) return;
    final question = widget.questions[_activeBox!];
    final isCorrect = optionIndex == question.correctIndex;
    QuestionMasteryService().recordAnswer(question, wasCorrect: isCorrect, uid: currentUid());
    setState(() {
      _selectedOption = optionIndex;
      if (isCorrect) _score++;
      _openedBoxes.add(_activeBox!);
    });
    if (isCorrect) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _backToBoxes() {
    if (_openedBoxes.length == widget.questions.length) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.questions.length,
            formatId: 'open-the-box',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _activeBox = null;
      _selectedOption = null;
    });
  }

  Color? _colorForOption(int optionIndex, int correctIndex) {
    if (_selectedOption == null) return null;
    if (optionIndex == correctIndex) return Colors.green;
    if (optionIndex == _selectedOption) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Open the Box (${_openedBoxes.length} von ${widget.questions.length})')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _activeBox == null ? _buildGrid(colorScheme) : _buildQuestion(colorScheme),
          ),
          ...feedbackOverlayLayers(),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme colorScheme) {
    return GridView.builder(
      itemCount: widget.questions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final opened = _openedBoxes.contains(index);
        return Material(
          color: opened ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: opened ? null : () => _openBox(index),
            child: Center(
              child: Icon(
                opened ? Icons.check_circle : Icons.card_giftcard,
                size: 36,
                color: opened ? colorScheme.onSurface.withValues(alpha: 0.4) : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestion(ColorScheme colorScheme) {
    final question = widget.questions[_activeBox!];
    final answered = _selectedOption != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.question,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        wrapWithShake(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < question.options.length; i++) ...[
                _buildOptionButton(context, i, question),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (answered) ...[
          Center(
            child: Text(
              _selectedOption == question.correctIndex
                  ? 'Richtig!'
                  : 'Leider falsch. Richtig wäre: "${question.options[question.correctIndex]}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _selectedOption == question.correctIndex ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _backToBoxes,
              child: Text(
                _openedBoxes.length == widget.questions.length ? 'Fertig' : 'Zurück zu den Boxen',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionButton(BuildContext context, int index, Question question) {
    final backgroundColor =
        _colorForOption(index, question.correctIndex) ?? Theme.of(context).colorScheme.primaryContainer;
    final textColor = _selectedOption == null ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectOption(index),
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
