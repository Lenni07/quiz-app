import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/career_ranking_entry.dart';
import '../services/career_service.dart';
import '../theme/app_theme.dart';
import '../widgets/count_up_number.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_panel.dart';
import '../widgets/maritime_icon.dart';

class CareerRankingScreen extends StatelessWidget {
  final bool embedded;

  const CareerRankingScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
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
            return EmptyState(icon: Icons.wifi_off, message: S.t('ranking_unavailable'));
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return EmptyState(
              iconWidget: const MaritimeIcon(MaritimeIconShape.shipWheel, size: 44, color: AppColors.brass),
              message: S.t('ranking_empty'),
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isMe = entry.uid == myUid;
              final medalColor = switch (index) {
                0 => const Color(0xFFFFD54F),
                1 => const Color(0xFFCFD8DC),
                2 => const Color(0xFFD7A86E),
                _ => null,
              };
              return GamePanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 14,
                borderColor: isMe ? AppColors.brassLight : null,
                gradient: isMe
                    ? const LinearGradient(colors: [AppColors.deepSeaLight, AppColors.brassDark])
                    : null,
                child: Row(
                  children: [
                    if (medalColor != null)
                      Icon(Icons.emoji_events, color: medalColor, size: 22)
                    else
                      Text('${index + 1}.', style: displayStyle(fontSize: 15, color: AppColors.canvas.withValues(alpha: 0.7))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? '${entry.displayName} ${S.t('ranking_you_suffix')}' : entry.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.canvas),
                          ),
                          if (entry.position != null && entry.position!.trim().isNotEmpty)
                            Text(
                              entry.position!,
                              style: TextStyle(fontSize: 12, color: AppColors.canvas.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                    CountUpNumber(entry.eloRating, style: displayStyle(fontSize: 16, color: AppColors.brassLight)),
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
