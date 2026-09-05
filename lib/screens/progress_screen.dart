import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/question.dart';
import '../services/question_mastery_service.dart';
import '../theme/app_theme.dart';
import '../utils/current_uid.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_panel.dart';
import '../widgets/maritime_background.dart';
import '../widgets/maritime_icon.dart';
import '../widgets/maritime_painters.dart';
import '../widgets/pop_in.dart';

/// Fortschrittsanzeige für den Lernmodus (siehe ROADMAP_QuizApp.md
/// Abschnitt 18e) - bewusst KEINE EP/Punkte, sondern Level-Fortschritt,
/// Schwachstellen-Erkennung und eine Liste noch nicht sicher sitzender
/// Inhalte. Nur für das Question-Modell (siehe question_mastery_service.dart).
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final Future<LearningProgress> _future = _load();

  Future<LearningProgress> _load() async {
    final questions = await loadQuestions();
    final uid = currentUid();
    if (uid != null) {
      // Bestmögliche Sicherung/Wiederherstellung vor der Anzeige (siehe
      // ROADMAP_QuizApp.md Abschnitt 18e) - lokal bleibt auch bei Fehlern
      // (z. B. offline) die maßgebliche Quelle, computeProgress() läuft
      // unabhängig davon immer.
      await QuestionMasteryService().syncWithCloud(uid, questions);
    }
    return QuestionMasteryService().computeProgress(questions);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
        appBar: AppBar(title: Text(S.t('progress_title'))),
        body: MaritimeBackground(
          child: FutureBuilder<LearningProgress>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(icon: Icons.wifi_off, message: S.t('progress_unavailable'));
              }
              final progress = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _SectionHeader(S.t('progress_levels_heading')),
                  const SizedBox(height: 12),
                  for (final level in progress.levels) ...[
                    PopIn(child: _LevelRow(level)),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  _SectionHeader(S.t('progress_weak_spots_heading')),
                  const SizedBox(height: 12),
                  if (progress.weakestTopics.isEmpty)
                    EmptyState(
                      iconWidget: const MaritimeIcon(MaritimeIconShape.compass, size: 40, color: AppColors.brass),
                      message: S.t('progress_weak_spots_empty'),
                    )
                  else
                    for (final topic in progress.weakestTopics) ...[
                      PopIn(child: _TopicRow(topic)),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 16),
                  _SectionHeader(S.t('progress_open_questions_heading')),
                  const SizedBox(height: 12),
                  if (progress.notYetMastered.isEmpty)
                    EmptyState(icon: Icons.emoji_events, message: S.t('progress_open_questions_empty'))
                  else
                    for (final question in progress.notYetMastered) ...[
                      _QuestionRow(question),
                      const SizedBox(height: 8),
                    ],
                ],
              );
            },
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: displayStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brassLight, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        const RopeDivider(height: 8),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final LevelProgress progress;

  const _LevelRow(this.progress);

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.f('progress_level_label', [progress.level]), style: displayStyle(fontSize: 16, color: AppColors.canvas)),
              Text('${progress.percent}%', style: displayStyle(fontSize: 16, color: AppColors.brassLight)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.plural('progress_level_detail', progress.totalCount, [progress.masteredCount, progress.totalCount]),
            style: TextStyle(fontSize: 12, color: AppColors.canvas.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicProgress progress;

  const _TopicRow(this.progress);

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      borderColor: AppColors.signalRed.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.trending_down, color: AppColors.signalRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progress.topic, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.canvas)),
                const SizedBox(height: 2),
                Text(
                  S.f('progress_weak_spot_detail', [progress.masteredCount, progress.attemptedCount]),
                  style: TextStyle(fontSize: 12, color: AppColors.canvas.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final Question question;

  const _QuestionRow(this.question);

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(question.question, style: const TextStyle(color: AppColors.canvas, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brass.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.brass.withValues(alpha: 0.5)),
            ),
            child: Text(
              'L${question.level}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brassLight),
            ),
          ),
        ],
      ),
    );
  }
}
