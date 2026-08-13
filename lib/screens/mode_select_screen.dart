import 'package:flutter/material.dart';
import '../models/image_quiz.dart';
import '../models/number_word.dart';
import '../models/question.dart';
import '../models/sentence.dart';
import '../models/true_false.dart';
import '../utils/page_transitions.dart';
import 'fill_blank_screen.dart';
import 'flashcard_category_screen.dart';
import 'gameshow_quiz_screen.dart';
import 'higher_lower_screen.dart';
import 'image_quiz_screen.dart';
import 'match_pairs_screen.dart';
import 'open_box_screen.dart';
import 'question_screen.dart';
import 'true_false_screen.dart';
import 'word_order_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  Future<void> _startGeneralQuiz(BuildContext context) async {
    final questions = await loadQuestions();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(QuestionScreen(questions: questions)));
    }
  }

  Future<void> _startConversationQuiz(BuildContext context) async {
    final sentences = await loadSentences();
    final questions = sentencesToQuestions(sentences);
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(QuestionScreen(questions: questions)));
    }
  }

  Future<void> _startFillBlank(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(FillBlankScreen(sentences: sentences)));
    }
  }

  Future<void> _startWordOrder(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(WordOrderScreen(sentences: sentences)));
    }
  }

  Future<void> _startTrueFalse(BuildContext context) async {
    final statements = await loadTrueFalseStatements();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(TrueFalseScreen(statements: statements)));
    }
  }

  Future<void> _startGameshowQuiz(BuildContext context) async {
    final questions = await loadQuestions();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(GameshowQuizScreen(questions: questions)));
    }
  }

  Future<void> _startImageQuiz(BuildContext context) async {
    final items = await loadImageQuizItems();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(ImageQuizScreen(items: items)));
    }
  }

  Future<void> _startHigherLower(BuildContext context) async {
    final words = await loadNumberWords();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(HigherLowerScreen(words: words)));
    }
  }

  Future<void> _startOpenBox(BuildContext context) async {
    final questions = await loadQuestions();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(OpenBoxScreen(questions: questions.take(9).toList())));
    }
  }

  Future<void> _startMatchPairs(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(MatchPairsScreen(sentences: sentences)));
    }
  }

  Future<void> _startFlashcards(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(FlashcardCategoryScreen(sentences: sentences)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modus wählen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('Grundmodi'),
            _ModeCard(
              title: 'Allgemeinwissen-Quiz',
              subtitle: '25 Wissensfragen zur deutschen Sprache',
              icon: Icons.public,
              onTap: () => _startGeneralQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Konversation üben',
              subtitle: '8 typische Vorstellungsfragen',
              icon: Icons.chat_bubble_outline,
              onTap: () => _startConversationQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Lückentext',
              subtitle: 'Fehlendes Wort eintippen',
              icon: Icons.short_text,
              onTap: () => _startFillBlank(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Richtige Reihenfolge',
              subtitle: 'Wörter in die richtige Reihenfolge bringen',
              icon: Icons.low_priority,
              onTap: () => _startWordOrder(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Karteikarten üben',
              subtitle: 'Selbst antworten, dann Musterantwort ansehen',
              icon: Icons.style_outlined,
              onTap: () => _startFlashcards(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Wahr oder Falsch',
              subtitle: 'Aussage lesen und richtig einschätzen',
              icon: Icons.rule,
              onTap: () => _startTrueFalse(context),
            ),
            const _SectionHeader('Weitere Formate'),
            _ModeCard(
              title: 'Gameshow-Quiz',
              subtitle: 'Antwort sperren, dann spannungsgeladen aufdecken',
              icon: Icons.theater_comedy,
              onTap: () => _startGameshowQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Bild-Quiz',
              subtitle: 'Symbol sehen, passendes Wort wählen',
              icon: Icons.image_outlined,
              onTap: () => _startImageQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Higher or Lower',
              subtitle: 'Welches Zahlwort ist größer?',
              icon: Icons.swap_vert,
              onTap: () => _startHigherLower(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Open the Box',
              subtitle: 'Box öffnen und versteckte Frage beantworten',
              icon: Icons.card_giftcard,
              onTap: () => _startOpenBox(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'Find the Match',
              subtitle: 'Memory: Deutsch und Englisch zusammenfinden',
              icon: Icons.grid_view,
              onTap: () => _startMatchPairs(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4);

    return Material(
      color: _enabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: foreground),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: foreground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: foreground.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              if (!_enabled)
                Icon(Icons.lock_outline, color: foreground)
              else
                Icon(Icons.chevron_right, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
