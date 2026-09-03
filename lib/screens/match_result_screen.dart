import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/game_format.dart';
import '../services/career_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/maritime_icon.dart';

class MatchResultScreen extends StatelessWidget {
  final String matchId;

  const MatchResultScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
      appBar: AppBar(title: Text(S.t('match_result_title')), automaticallyImplyLeading: false),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: CareerMatchService().watchMatch(matchId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final winnerUid = data['winnerUid'] as String?;
          final roundWinners = List<dynamic>.from(data['roundWinners'] as List);
          final formats = List<String>.from(data['formats'] as List);
          final eloChange = (data['eloChange'] as Map?)?.cast<String, dynamic>();
          final myWins = roundWinners.where((w) => w == myUid).length;
          final opponentWins = roundWinners.where((w) => w != null && w != myUid).length;

          final String headline;
          final Color headlineColor;
          if (winnerUid == null) {
            headline = S.t('match_draw');
            headlineColor = colorScheme.primary;
          } else if (winnerUid == myUid) {
            headline = S.t('match_win');
            headlineColor = Colors.greenAccent.shade400;
          } else {
            headline = S.t('match_loss');
            headlineColor = AppColors.signalRed;
          }

          final myNewRating = eloChange != null && myUid != null ? eloChange[myUid] as int? : null;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  winnerUid == myUid
                      ? Icon(Icons.emoji_events, size: 90, color: headlineColor)
                      : MaritimeIcon(MaritimeIconShape.crossedOars, size: 90, color: headlineColor),
                  const SizedBox(height: 24),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: displayStyle(fontSize: 30, color: headlineColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.f('match_rounds_label', [myWins, opponentWins]),
                    style: displayStyle(fontSize: 20, color: AppColors.canvas),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formats.map((f) => gameFormatById(f).displayName).join(' · '),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  if (myNewRating != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      S.f('match_new_rating', [myNewRating]),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 48),
                  GameButton(
                    label: S.t('match_back_to_start'),
                    icon: Icons.home_outlined,
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
