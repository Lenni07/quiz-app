import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../utils/page_transitions.dart';
import 'flashcard_screen.dart';

class FlashcardCategoryScreen extends StatelessWidget {
  final List<Sentence> sentences;

  const FlashcardCategoryScreen({super.key, required this.sentences});

  void _start(BuildContext context, {required String languageCode, required String languageLabel}) {
    Navigator.push(
      context,
      buildFadeSlideRoute(
        FlashcardScreen(
          sentences: sentences,
          languageCode: languageCode,
          languageLabel: languageLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorie wählen')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoryCard(
              title: 'Deutsch–Englisch',
              icon: Icons.language,
              onTap: () => _start(context, languageCode: 'en', languageLabel: 'Englisch'),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              title: 'Deutsch–Tagalog',
              icon: Icons.language,
              onTap: () => _start(context, languageCode: 'tl', languageLabel: 'Tagalog'),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              title: 'Deutsch–Bahasa',
              icon: Icons.language,
              onTap: () => _start(context, languageCode: 'id', languageLabel: 'Bahasa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.onSurface),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
