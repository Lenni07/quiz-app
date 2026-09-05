import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import '../widgets/answer_feedback.dart';
import 'result_screen.dart';

class _Pair {
  final int id;
  final String german;
  final String english;

  _Pair({required this.id, required this.german, required this.english});
}

class MatchUpScreen extends StatefulWidget {
  final List<Sentence> sentences;
  final int pairsPerRound;

  const MatchUpScreen({super.key, required this.sentences, this.pairsPerRound = 4});

  @override
  State<MatchUpScreen> createState() => _MatchUpScreenState();
}

class _MatchUpScreenState extends State<MatchUpScreen> with AnswerFeedbackMixin {
  late final List<_Pair> _allPairs;
  late final List<List<_Pair>> _rounds;
  int _roundIndex = 0;
  int _attempts = 0;
  final Set<int> _matchedPairIds = {};
  late List<_Pair> _germanOrder;
  late List<_Pair> _englishOrder;

  @override
  void initState() {
    super.initState();
    _allPairs = _buildPairs();
    _rounds = [];
    for (var i = 0; i < _allPairs.length; i += widget.pairsPerRound) {
      _rounds.add(_allPairs.sublist(i, min(i + widget.pairsPerRound, _allPairs.length)));
    }
    _setUpRound();
  }

  List<_Pair> _buildPairs() {
    final pairs = <_Pair>[];
    for (var i = 0; i < widget.sentences.length; i++) {
      final sentence = widget.sentences[i];
      final translation = sentence.translations['en'];
      if (translation == null) continue;
      pairs.add(_Pair(id: i, german: sentence.question, english: translation.question));
    }
    return pairs;
  }

  void _setUpRound() {
    final round = _rounds[_roundIndex];
    _matchedPairIds.clear();
    _germanOrder = List<_Pair>.from(round)..shuffle(Random());
    _englishOrder = List<_Pair>.from(round)..shuffle(Random());
  }

  void _handleDrop(int draggedPairId, int targetPairId) {
    final isCorrect = draggedPairId == targetPairId;
    setState(() {
      _attempts++;
      if (isCorrect) {
        _matchedPairIds.add(draggedPairId);
      }
    });

    if (_matchedPairIds.length == _rounds[_roundIndex].length) {
      triggerCorrectFeedback();
      Future.delayed(const Duration(milliseconds: 500), _advance);
    } else if (isCorrect) {
      HapticFeedback.mediumImpact();
    } else {
      triggerWrongFeedback();
    }
  }

  void _advance() {
    if (!mounted) return;
    final isLastRound = _roundIndex == _rounds.length - 1;
    if (isLastRound) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _allPairs.length,
            total: _attempts,
            formatId: 'match-up',
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _roundIndex++;
      _setUpRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Up (Runde ${_roundIndex + 1} von ${_rounds.length}, $_attempts Versuche)'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: wrapWithShake(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var pair in _germanOrder)
                          if (!_matchedPairIds.contains(pair.id)) _buildDraggable(context, pair),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var pair in _englishOrder) _buildTarget(context, pair),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...feedbackOverlayLayers(),
        ],
      ),
    );
  }

  Widget _buildDraggable(BuildContext context, _Pair pair) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(
        pair.german,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onPrimaryContainer),
      ),
    );

    return Draggable<int>(
      data: pair.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 150, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  Widget _buildTarget(BuildContext context, _Pair pair) {
    final colorScheme = Theme.of(context).colorScheme;
    final matched = _matchedPairIds.contains(pair.id);

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !matched,
      onAcceptWithDetails: (details) => _handleDrop(details.data, pair.id),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: matched
                ? Colors.green.withValues(alpha: 0.4)
                : highlighted
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
          ),
          child: Text(
            matched ? '${pair.english} ✓' : pair.english,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
