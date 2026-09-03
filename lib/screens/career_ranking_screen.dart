import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/career_ranking_entry.dart';
import '../services/career_service.dart';

class CareerRankingScreen extends StatelessWidget {
  final bool embedded;

  const CareerRankingScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final body = ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: StreamBuilder<List<CareerRankingEntry>>(
        stream: CareerService().watchRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(S.t('ranking_unavailable'), style: const TextStyle(color: Colors.red)),
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Text(
                S.t('ranking_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isMe = entry.uid == myUid;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? '${entry.displayName} ${S.t('ranking_you_suffix')}' : entry.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (entry.position != null && entry.position!.trim().isNotEmpty)
                            Text(
                              entry.position!,
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                    Text('${entry.eloRating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
      ),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('tab_ranking'))),
      body: body,
    );
  }
}
