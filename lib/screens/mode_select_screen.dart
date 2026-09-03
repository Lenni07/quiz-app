import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/department.dart';
import '../models/flip_tile_word.dart';
import '../models/game_format.dart';
import '../models/group_sort.dart';
import '../models/image_quiz.dart';
import '../models/number_word.dart';
import '../models/question.dart';
import '../models/sentence.dart';
import '../models/true_false.dart';
import '../services/user_profile_service.dart';
import '../utils/page_transitions.dart';
import 'duel_mode_screen.dart';
import 'fill_blank_screen.dart';
import 'flashcard_category_screen.dart';
import 'flip_tiles_screen.dart';
import 'gameshow_quiz_screen.dart';
import 'group_sort_screen.dart';
import 'image_quiz_screen.dart';
import 'listening_screen.dart';
import 'match_pairs_screen.dart';
import 'match_up_screen.dart';
import 'open_box_screen.dart';
import 'question_screen.dart';
import 'random_wheel_screen.dart';
import 'rank_order_screen.dart';
import 'true_false_screen.dart';
import 'word_magnets_screen.dart';
import 'word_order_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  /// Wenn true, wird kein eigenes Scaffold/AppBar gezeichnet - für die
  /// Einbettung als Reiter-Inhalt (siehe main_tabs_screen.dart).
  final bool embedded;

  const ModeSelectScreen({super.key, this.embedded = false});

  /// Liest das eigene Department fürs Filtern von Question-Inhalten im
  /// Lernmodus (siehe ROADMAP_QuizApp.md Abschnitt 18c). Robust gegen
  /// fehlendes Firebase/fehlenden Login - dann einfach kein Filter (null).
  Future<String?> _myDepartment() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final data = await UserProfileService().loadProfile(uid);
      return data?['department'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startGeneralQuiz(BuildContext context) async {
    final questions = questionsForLearning(await loadQuestions(), await _myDepartment());
    if (context.mounted) {
      Navigator.push(
        context,
        buildFadeSlideRoute(QuestionScreen(questions: questions, formatId: 'allgemeinwissen-quiz')),
      );
    }
  }

  Future<void> _startConversationQuiz(BuildContext context) async {
    final sentences = await loadSentences();
    final questions = sentencesToQuestions(sentences);
    if (context.mounted) {
      Navigator.push(
        context,
        buildFadeSlideRoute(QuestionScreen(questions: questions, formatId: 'konversation-ueben')),
      );
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
    final questions = questionsForLearning(await loadQuestions(), await _myDepartment());
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

  Future<void> _startOpenBox(BuildContext context) async {
    final questions = questionsForLearning(await loadQuestions(), await _myDepartment());
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

  Future<void> _startRandomWheel(BuildContext context) async {
    final questions = questionsForLearning(await loadQuestions(), await _myDepartment());
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(RandomWheelScreen(questions: questions)));
    }
  }

  Future<void> _startFlipTiles(BuildContext context) async {
    final words = await loadFlipTileWords();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(FlipTilesScreen(words: words)));
    }
  }

  Future<void> _startMatchUp(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(MatchUpScreen(sentences: sentences)));
    }
  }

  Future<void> _startWordMagnets(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(WordMagnetsScreen(sentences: sentences)));
    }
  }

  Future<void> _startGroupSort(BuildContext context) async {
    final data = await loadGroupSortData();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(GroupSortScreen(data: data)));
    }
  }

  Future<void> _startRankOrder(BuildContext context) async {
    final words = await loadNumberWords();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(RankOrderScreen(words: words)));
    }
  }

  Future<void> _startFlashcards(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(FlashcardCategoryScreen(sentences: sentences)));
    }
  }

  void _startDuel(BuildContext context) {
    Navigator.push(context, buildFadeSlideRoute(const DuelModeScreen()));
  }

  Future<void> _startListening(BuildContext context) async {
    final sentences = await loadSentences();
    if (context.mounted) {
      Navigator.push(context, buildFadeSlideRoute(ListeningScreen(sentences: sentences)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reagiert auf Sprachwechsel (siehe ROADMAP_QuizApp.md Abschnitt 19) -
    // die Formatnamen/-untertitel hier gehören zur Bedienoberfläche, die
    // Inhalte innerhalb der Formate selbst bleiben Deutsch.
    final body = ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _SectionHeader(S.t('section_basics')),
            _ModeCard(
              title: gameFormatById('hoerverstehen').displayName,
              subtitle: S.t('format_hoerverstehen_subtitle'),
              icon: Icons.headphones,
              onTap: () => _startListening(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('allgemeinwissen-quiz').displayName,
              subtitle: S.t('format_allgemeinwissen-quiz_subtitle'),
              icon: Icons.public,
              onTap: () => _startGeneralQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('konversation-ueben').displayName,
              subtitle: S.t('format_konversation-ueben_subtitle'),
              icon: Icons.chat_bubble_outline,
              onTap: () => _startConversationQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('lueckentext').displayName,
              subtitle: S.t('format_lueckentext_subtitle'),
              icon: Icons.short_text,
              onTap: () => _startFillBlank(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('richtige-reihenfolge').displayName,
              subtitle: S.t('format_richtige-reihenfolge_subtitle'),
              icon: Icons.low_priority,
              onTap: () => _startWordOrder(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('karteikarten').displayName,
              subtitle: S.t('format_karteikarten_subtitle'),
              icon: Icons.style_outlined,
              onTap: () => _startFlashcards(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('wahr-oder-falsch').displayName,
              subtitle: S.t('format_wahr-oder-falsch_subtitle'),
              icon: Icons.rule,
              onTap: () => _startTrueFalse(context),
            ),
            _SectionHeader(S.t('section_more_formats')),
            _ModeCard(
              title: gameFormatById('gameshow-quiz').displayName,
              subtitle: S.t('format_gameshow-quiz_subtitle'),
              icon: Icons.theater_comedy,
              onTap: () => _startGameshowQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('bild-quiz').displayName,
              subtitle: S.t('format_bild-quiz_subtitle'),
              icon: Icons.image_outlined,
              onTap: () => _startImageQuiz(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('open-the-box').displayName,
              subtitle: S.t('format_open-the-box_subtitle'),
              icon: Icons.card_giftcard,
              onTap: () => _startOpenBox(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('find-the-match').displayName,
              subtitle: S.t('format_find-the-match_subtitle'),
              icon: Icons.grid_view,
              onTap: () => _startMatchPairs(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('random-wheel').displayName,
              subtitle: S.t('format_random-wheel_subtitle'),
              icon: Icons.donut_large,
              onTap: () => _startRandomWheel(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('flip-tiles').displayName,
              subtitle: S.t('format_flip-tiles_subtitle'),
              icon: Icons.view_module,
              onTap: () => _startFlipTiles(context),
            ),
            _SectionHeader(S.t('section_drag_drop')),
            _ModeCard(
              title: gameFormatById('match-up').displayName,
              subtitle: S.t('format_match-up_subtitle'),
              icon: Icons.compare_arrows,
              onTap: () => _startMatchUp(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('word-magnets').displayName,
              subtitle: S.t('format_word-magnets_subtitle'),
              icon: Icons.dashboard_customize,
              onTap: () => _startWordMagnets(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('group-sort').displayName,
              subtitle: S.t('format_group-sort_subtitle'),
              icon: Icons.category,
              onTap: () => _startGroupSort(context),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: gameFormatById('rank-order').displayName,
              subtitle: S.t('format_rank-order_subtitle'),
              icon: Icons.sort,
              onTap: () => _startRankOrder(context),
            ),
            _SectionHeader(S.t('section_multiplayer')),
            _ModeCard(
              title: S.t('duel_title'),
              subtitle: S.t('duel_subtitle'),
              icon: Icons.people_alt,
              onTap: () => _startDuel(context),
            ),
          ],
        ),
      ),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('tab_learn'))),
      body: body,
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
