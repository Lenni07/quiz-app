import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flip_tile_word.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class FlipTilesScreen extends StatefulWidget {
  final List<FlipTileWord> words;

  const FlipTilesScreen({super.key, required this.words});

  @override
  State<FlipTilesScreen> createState() => _FlipTilesScreenState();
}

class _FlipTilesScreenState extends State<FlipTilesScreen> {
  int _currentIndex = 0;
  int _score = 0;
  late Set<int> _flippedTiles;
  late List<String> _optionWords;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    _setUpRound();
  }

  void _setUpRound() {
    _flippedTiles = {};
    _selectedWord = null;
    final random = Random();
    final correctWord = widget.words[_currentIndex].word;
    final others = widget.words.where((w) => w.word != correctWord).map((w) => w.word).toList()..shuffle(random);
    _optionWords = [correctWord, ...others.take(3)]..shuffle(random);
  }

  void _flipTile(int index) {
    if (_selectedWord != null) return;
    setState(() => _flippedTiles.add(index));
  }

  void _chooseWord(String word) {
    if (_selectedWord != null) return;
    final isCorrect = word == widget.words[_currentIndex].word;
    setState(() {
      _selectedWord = word;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    final isLast = _currentIndex == widget.words.length - 1;
    if (isLast) {
      Navigator.push(
        context,
        buildFadeSlideRoute(
          ResultScreen(
            score: _score,
            total: widget.words.length,
            onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _setUpRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.words[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final answered = _selectedWord != null;
    final isLast = _currentIndex == widget.words.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Flip Tiles ${_currentIndex + 1} von ${widget.words.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stufe: $_score von ${widget.words.length}',
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Text(
              'Englischer Hinweis: "${entry.clue}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < entry.word.length; i++) _buildTile(context, i, entry.word[i]),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Welches Wort ist gesucht?',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            for (var word in _optionWords) ...[
              _buildOption(context, word, entry.word),
              const SizedBox(height: 12),
            ],
            if (answered)
              Center(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Fertig' : 'Nächstes Wort'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, int index, String letter) {
    final colorScheme = Theme.of(context).colorScheme;
    final revealed = _flippedTiles.contains(index) || _selectedWord != null;

    return GestureDetector(
      onTap: () => _flipTile(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 48,
        decoration: BoxDecoration(
          color: revealed ? colorScheme.secondaryContainer : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          revealed ? letter : '?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String word, String correctWord) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.primaryContainer;
    if (_selectedWord != null) {
      if (word == correctWord) {
        backgroundColor = Colors.green;
      } else if (word == _selectedWord) {
        backgroundColor = Colors.red;
      }
    }
    final textColor = _selectedWord == null ? colorScheme.onPrimaryContainer : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _chooseWord(word),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
