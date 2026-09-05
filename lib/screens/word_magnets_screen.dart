import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';
import 'result_screen.dart';

class _Magnet {
  final int id;
  final String text;

  _Magnet({required this.id, required this.text});
}

class WordMagnetsScreen extends StatefulWidget {
  final List<Sentence> sentences;

  const WordMagnetsScreen({super.key, required this.sentences});

  @override
  State<WordMagnetsScreen> createState() => _WordMagnetsScreenState();
}

class _WordMagnetsScreenState extends State<WordMagnetsScreen> with AnswerFeedbackMixin {
  int _currentIndex = 0;
  int _score = 0;
  late List<_Magnet> _pool;
  late List<_Magnet?> _slots;
  bool _checked = false;
  bool? _isCorrect;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _setUpSentence();
  }

  void _setUpSentence() {
    final sentence = widget.sentences[_currentIndex];
    final words = sentence.words;
    final random = Random();

    final otherWords = <String>[];
    for (var i = 0; i < widget.sentences.length; i++) {
      if (i == _currentIndex) continue;
      otherWords.addAll(widget.sentences[i].words.where((w) => !words.contains(w)));
    }
    otherWords.shuffle(random);
    final decoys = otherWords.take(2).toList();

    final allWords = [...words, ...decoys];
    _pool = allWords.map((w) => _Magnet(id: _nextId++, text: w)).toList()..shuffle(random);
    _slots = List<_Magnet?>.filled(words.length, null);
    _checked = false;
    _isCorrect = null;
  }

  void _placeMagnet(_Magnet magnet, int slotIndex) {
    if (_checked || _slots[slotIndex] != null) return;
    setState(() {
      _slots[slotIndex] = magnet;
      _pool.removeWhere((m) => m.id == magnet.id);
    });
  }

  void _clearSlot(int slotIndex) {
    if (_checked) return;
    final magnet = _slots[slotIndex];
    if (magnet == null) return;
    setState(() {
      _pool.add(magnet);
      _slots[slotIndex] = null;
    });
  }

  void _check() {
    final correctWords = widget.sentences[_currentIndex].words;
    final isCorrect = List.generate(_slots.length, (i) => _slots[i]?.text)
        .asMap()
        .entries
        .every((entry) => entry.value == correctWords[entry.key]);
    setState(() {
      _checked = true;
      _isCorrect = isCorrect;
      if (isCorrect) _score++;
    });
    if (isCorrect) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _next() {
    final isLast = _currentIndex == widget.sentences.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.sentences.length,
            formatId: 'word-magnets',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _setUpSentence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentences[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final allSlotsFilled = _slots.every((s) => s != null);
    final isLast = _currentIndex == widget.sentences.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Word Magnets ${_currentIndex + 1} von ${widget.sentences.length}')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Stufe: ', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                CountUpNumber(_score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                Text(' von ${widget.sentences.length}', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sentence.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Text('Satz bauen:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            wrapWithShake(
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _slots.length; i++) _buildSlot(context, i),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Wort-Magnete:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (var magnet in _pool) _buildMagnet(context, magnet)],
            ),
            const SizedBox(height: 24),
            if (!_checked)
              Center(
                child: ElevatedButton(
                  onPressed: allSlotsFilled ? _check : null,
                  child: const Text('Prüfen'),
                ),
              )
            else ...[
              Center(
                child: Text(
                  _isCorrect == true ? 'Richtig!' : 'Leider falsch. Richtig wäre: "${sentence.correctAnswer}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect == true ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Fertig' : 'Weiter'),
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

  Widget _buildSlot(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final magnet = _slots[index];
    final correctWords = widget.sentences[_currentIndex].words;
    Color borderColor = colorScheme.outline;
    if (_checked && magnet != null) {
      borderColor = magnet.text == correctWords[index] ? Colors.green : Colors.red;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => magnet == null && !_checked,
      onAcceptWithDetails: (details) {
        final dragged = _pool.firstWhere((m) => m.id == details.data);
        _placeMagnet(dragged, index);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _clearSlot(index),
          child: Container(
            constraints: const BoxConstraints(minWidth: 70, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: magnet != null ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              magnet?.text ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMagnet(BuildContext context, _Magnet magnet) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
      child: Text(magnet.text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    return Draggable<int>(
      data: magnet.id,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}
