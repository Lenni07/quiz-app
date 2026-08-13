import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class _Tile {
  final int pairId;
  final String text;
  bool matched = false;

  _Tile({required this.pairId, required this.text});
}

class MatchPairsScreen extends StatefulWidget {
  final List<Sentence> sentences;

  const MatchPairsScreen({super.key, required this.sentences});

  @override
  State<MatchPairsScreen> createState() => _MatchPairsScreenState();
}

class _MatchPairsScreenState extends State<MatchPairsScreen> {
  late final List<_Tile> _tiles;
  final List<int> _flippedIndices = [];
  final Set<int> _matchedPairIds = {};
  int _attempts = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _tiles = _buildTiles();
  }

  List<_Tile> _buildTiles() {
    final tiles = <_Tile>[];
    for (var i = 0; i < widget.sentences.length; i++) {
      final sentence = widget.sentences[i];
      final translation = sentence.translations['en'];
      if (translation == null) continue;
      tiles.add(_Tile(pairId: i, text: sentence.question));
      tiles.add(_Tile(pairId: i, text: translation.question));
    }
    tiles.shuffle(Random());
    return tiles;
  }

  int get _totalPairs => _tiles.length ~/ 2;

  void _tapTile(int index) {
    if (_checking) return;
    if (_tiles[index].matched) return;
    if (_flippedIndices.contains(index)) return;
    if (_flippedIndices.length == 2) return;

    setState(() => _flippedIndices.add(index));

    if (_flippedIndices.length == 2) {
      _attempts++;
      final first = _tiles[_flippedIndices[0]];
      final second = _tiles[_flippedIndices[1]];
      if (first.pairId == second.pairId) {
        setState(() {
          first.matched = true;
          second.matched = true;
          _matchedPairIds.add(first.pairId);
          _flippedIndices.clear();
        });
        if (_matchedPairIds.length == _totalPairs) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            Navigator.push(
              context,
              buildFadeSlideRoute(
                ResultScreen(
                  score: _totalPairs,
                  total: _attempts,
                  onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ),
            );
          });
        }
      } else {
        _checking = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _flippedIndices.clear();
            _checking = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Find the Match (${_matchedPairIds.length} von $_totalPairs, $_attempts Versuche)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: _tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final tile = _tiles[index];
            final revealed = tile.matched || _flippedIndices.contains(index);
            return Material(
              color: tile.matched
                  ? Colors.green.withValues(alpha: 0.4)
                  : revealed
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _tapTile(index),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: revealed
                        ? Text(
                            tile.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          )
                        : Icon(Icons.help_outline, color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
