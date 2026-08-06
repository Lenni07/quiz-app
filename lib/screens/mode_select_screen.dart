import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'question_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modus wählen')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const _ModeCard(
              title: 'Lückentext',
              subtitle: 'Bald verfügbar',
              icon: Icons.short_text,
              onTap: null,
            ),
            const SizedBox(height: 16),
            const _ModeCard(
              title: 'Richtige Reihenfolge',
              subtitle: 'Bald verfügbar',
              icon: Icons.low_priority,
              onTap: null,
            ),
          ],
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
