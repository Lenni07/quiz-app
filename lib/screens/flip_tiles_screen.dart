import 'package:flutter/material.dart';
import '../models/flip_tile_word.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

const int _maxWrongGuesses = 6;
const List<String> _keyboardLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'Ä', 'Ö', 'Ü',
];

class FlipTilesScreen extends StatefulWidget {
  final List<FlipTileWord> words;

  const FlipTilesScreen({super.key, required this.words});

  @override
  State<FlipTilesScreen> createState() => _FlipTilesScreenState();
}

class _FlipTilesScreenState extends State<FlipTilesScreen> {
  int _currentIndex = 0;
  int _score = 0;
  late Set<String> _guessedLetters;
  int _wrongGuesses = 0;
  bool _roundOver = false;
  bool _roundWon = false;

  @override
  void initState() {
    super.initState();
    _setUpRound();
  }

  void _setUpRound() {
    _guessedLetters = {};
    _wrongGuesses = 0;
    _roundOver = false;
    _roundWon = false;
  }

  void _guessLetter(String letter) {
    if (_roundOver || _guessedLetters.contains(letter)) return;
    final word = widget.words[_currentIndex].word;
    setState(() {
      _guessedLetters.add(letter);
      if (!word.contains(letter)) {
        _wrongGuesses++;
        if (_wrongGuesses >= _maxWrongGuesses) {
          _roundOver = true;
          _roundWon = false;
        }
      } else {
        final solved = word.split('').every((l) => _guessedLetters.contains(l));
        if (solved) {
          _roundOver = true;
          _roundWon = true;
          _score++;
        }
      }
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
            formatId: 'flip-tiles',
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
            const SizedBox(height: 8),
            Text(
              'Fehlversuche: $_wrongGuesses von $_maxWrongGuesses',
              style: TextStyle(
                fontSize: 14,
                color: _wrongGuesses >= _maxWrongGuesses - 1
                    ? Colors.red
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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
                for (var i = 0; i < entry.word.length; i++) _buildTile(context, entry.word[i]),
              ],
            ),
            const SizedBox(height: 24),
            if (!_roundOver)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [for (var letter in _keyboardLetters) _buildKey(context, letter, entry.word)],
              )
            else ...[
              Center(
                child: Text(
                  _roundWon ? 'Richtig erraten!' : 'Leider nicht geschafft. Das Wort war "${entry.word}".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _roundWon ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Fertig' : 'Nächstes Wort'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String letter) {
    final colorScheme = Theme.of(context).colorScheme;
    final revealed = _guessedLetters.contains(letter) || _roundOver;

    return AnimatedContainer(
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
    );
  }

  Widget _buildKey(BuildContext context, String letter, String word) {
    final colorScheme = Theme.of(context).colorScheme;
    final guessed = _guessedLetters.contains(letter);
    Color backgroundColor = colorScheme.primaryContainer;
    if (guessed) {
      backgroundColor = word.contains(letter) ? Colors.green : colorScheme.surfaceContainerHighest;
    }
    final textColor = guessed && word.contains(letter) ? Colors.white : null;

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: guessed ? null : () => _guessLetter(letter),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
