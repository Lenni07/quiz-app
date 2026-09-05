import 'dart:math';
import 'package:flutter/material.dart';
import '../models/number_word.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/count_up_number.dart';
import 'result_screen.dart';

class RankOrderScreen extends StatefulWidget {
  final List<NumberWord> words;
  final int roundCount;
  final int itemsPerRound;

  const RankOrderScreen({
    super.key,
    required this.words,
    this.roundCount = 5,
    this.itemsPerRound = 5,
  });

  @override
  State<RankOrderScreen> createState() => _RankOrderScreenState();
}

class _RankOrderScreenState extends State<RankOrderScreen> with AnswerFeedbackMixin {
  int _round = 0;
  int _score = 0;
  late List<NumberWord> _current;
  bool _checked = false;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _setUpRound();
  }

  void _setUpRound() {
    final shuffled = List<NumberWord>.from(widget.words)..shuffle(Random());
    _current = shuffled.take(min(widget.itemsPerRound, shuffled.length)).toList()..shuffle(Random());
    _checked = false;
    _isCorrect = null;
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_checked) return;
    setState(() {
      final item = _current.removeAt(oldIndex);
      _current.insert(newIndex, item);
    });
  }

  void _check() {
    final isSorted = List.generate(_current.length - 1, (i) => _current[i].value <= _current[i + 1].value)
        .every((ok) => ok);
    setState(() {
      _checked = true;
      _isCorrect = isSorted;
      if (isSorted) _score++;
    });
    if (isSorted) {
      triggerCorrectFeedback();
    } else {
      triggerWrongFeedback();
    }
  }

  void _next() {
    final isLast = _round == widget.roundCount - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.roundCount,
            formatId: 'rank-order',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _round++;
      _setUpRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _round == widget.roundCount - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Rank Order ${_round + 1} von ${widget.roundCount}')),
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
                    Text(' von ${widget.roundCount}', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ordne die Zahlwörter von klein nach groß (ziehen zum Sortieren):',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: wrapWithShake(
                    ReorderableListView.builder(
                      itemCount: _current.length,
                      onReorderItem: _reorder,
                      itemBuilder: (context, index) {
                        final word = _current[index];
                        return Container(
                          key: ValueKey(word.word),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('${index + 1}.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(word.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_checked)
                  Center(
                    child: ElevatedButton(
                      onPressed: _check,
                      child: const Text('Prüfen'),
                    ),
                  )
                else ...[
                  Center(
                    child: Text(
                      _isCorrect == true
                          ? 'Richtig sortiert!'
                          : 'Leider nicht ganz richtig. Richtig wäre: '
                              '${(List<NumberWord>.from(_current)..sort((a, b) => a.value.compareTo(b.value))).map((w) => w.word).join(', ')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isCorrect == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Fertig' : 'Nächste Runde'),
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
}
