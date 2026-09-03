import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/game_format.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/game_button.dart';
import '../widgets/game_panel.dart';
import '../widgets/maritime_background.dart';
import '../widgets/maritime_icon.dart';
import '../widgets/maritime_painters.dart';
import 'career_ranking_screen.dart';
import 'fleet_war_screen.dart';
import 'mode_select_screen.dart';
import 'one_vs_one_queue_screen.dart';
import 'profile_screen.dart';

/// Hauptnavigation im Clash-Royale-Stil (siehe ROADMAP_QuizApp.md
/// Abschnitt 16): untere Reiter-Leiste mit 5 gleichrangigen Bereichen,
/// "1 vs 1" mittig und optisch hervorgehoben. Oben ein einfacher
/// Level/Wertungs-Kopfbereich statt Gold/Diamanten (keine Ingame-Währung
/// geplant) - "Level" wird hier bewusst einfach aus der ELO-Wertung
/// abgeleitet, da es noch kein eigenes XP-System gibt.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _index = 2;

  static const List<IconData?> _tabIcons = [
    Icons.school_outlined,
    Icons.directions_boat_filled,
    null,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];
  static const _tabLabelKeys = ['tab_learn', 'tab_fleet', 'tab_1v1', 'tab_ranking', 'tab_profile'];

  Widget _buildActiveTab(BuildContext context) {
    // Baut bewusst nur den gerade aktiven Reiter (statt z. B. IndexedStack
    // mit allen 5 gleichzeitig) - sonst würden auch inaktive Reiter sofort
    // Firebase-Dienste anfassen, was die App bei fehlendem Firebase (siehe
    // main.dart, offline-first) komplett zum Absturz bringen könnte.
    switch (_index) {
      case 0:
        return const ModeSelectScreen(embedded: true);
      case 1:
        return const FleetWarScreen(embedded: true);
      case 2:
        return _buildOneVsOneLanding(context);
      case 3:
        return const CareerRankingScreen(embedded: true);
      default:
        return const ProfileScreen(embedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reagiert auf Sprachwechsel (siehe ROADMAP_QuizApp.md Abschnitt 19) -
    // wichtig, da der Umschalter selbst im Profil-Reiter liegt, also einem
    // Kind dieses Widgets, und dieses Widget davon sonst nichts mitbekäme.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Scaffold(
        appBar: _buildHeader(context),
        body: MaritimeBackground(
          child: Column(
            children: [
              const WaveDivider(height: 10, color: AppColors.deepSea, waveLength: 32),
              Expanded(child: _buildActiveTab(context)),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.deepSea,
          selectedItemColor: AppColors.brassLight,
          unselectedItemColor: AppColors.canvas.withValues(alpha: 0.6),
          selectedLabelStyle: displayStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          currentIndex: _index,
          onTap: (index) => setState(() => _index = index),
          items: [
            for (var i = 0; i < _tabIcons.length; i++)
              BottomNavigationBarItem(
                icon: i == 2
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white24, width: 1.5)),
                          boxShadow: [
                            BoxShadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 6),
                          ],
                        ),
                        child: const MaritimeIcon(MaritimeIconShape.crossedOars, color: AppColors.deepSeaDark),
                      )
                    : Icon(_tabIcons[i]),
                label: S.t(_tabLabelKeys[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneVsOneLanding(BuildContext context) {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      uid = null;
    }
    return _OneVsOneLanding(uid: uid);
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    // Robust gegen "Firebase nicht erreichbar" (offline oder z. B. im Test) -
    // die App bleibt dann nutzbar, nur ohne Level/Wertungsanzeige.
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      uid = null;
    }
    return AppBar(
      automaticallyImplyLeading: false,
      title: uid == null
          ? Text(S.t('app_title'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final rating = (snapshot.data?.data()?['eloRating'] as num?)?.toInt() ?? 1000;
                final level = rating ~/ 100;
                final progress = (rating % 100) / 100;
                final streak = ((snapshot.data?.data()?['dailyChallenge'] as Map<String, dynamic>?)?['streak'] as num?)?.toInt() ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text('$level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: progress, minHeight: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 2),
                          Text(S.f('streak_label', [streak]), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 18),
                        const SizedBox(width: 4),
                        Text('$rating'),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Dichteres 1-vs-1-Startbild statt eines einzelnen Icons in großer Leere
/// (siehe ROADMAP_QuizApp.md Abschnitt 13a/13b): aktuelle Wertung, Streak,
/// Saison-Platzierung und die letzten Matches.
class _OneVsOneLanding extends StatelessWidget {
  final String? uid;

  const _OneVsOneLanding({required this.uid});

  @override
  Widget build(BuildContext context) {
    final myUid = uid;
    if (myUid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(S.t('queue_no_account'), textAlign: TextAlign.center),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePanel(
            child: Column(
              children: [
                const MaritimeIcon(MaritimeIconShape.crossedOars, size: 56, color: AppColors.brassLight),
                const SizedBox(height: 8),
                Text(S.t('tab_1v1'), style: displayStyle(fontSize: 26, color: AppColors.canvas)),
                const SizedBox(height: 6),
                Text(
                  S.t('landing_1v1_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 20),
                GameButton(
                  label: S.t('landing_1v1_button'),
                  icon: Icons.flash_on,
                  onPressed: () {
                    Navigator.push(context, buildFadeSlideRoute(const OneVsOneQueueScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
            builder: (context, snapshot) {
              final rating = (snapshot.data?.data()?['eloRating'] as num?)?.toInt() ?? 1000;
              final streak = ((snapshot.data?.data()?['dailyChallenge'] as Map<String, dynamic>?)?['streak'] as num?)?.toInt() ?? 0;
              return Row(
                children: [
                  Expanded(child: _StatTile(icon: Icons.emoji_events, label: S.t('profile_rating_label'), value: '$rating')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(icon: Icons.local_fire_department, label: S.t('streak_tile_label'), value: '$streak')),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SeasonRankTile(uid: myUid),
          const SizedBox(height: 24),
          Text(S.t('recent_matches_title'), style: displayStyle(fontSize: 16, color: AppColors.canvas)),
          const SizedBox(height: 8),
          _RecentMatchesList(uid: myUid),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(icon, color: AppColors.brassLight),
          const SizedBox(height: 6),
          Text(value, style: displayStyle(fontSize: 20, color: AppColors.canvas)),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.canvas.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _SeasonRankTile extends StatelessWidget {
  final String uid;

  const _SeasonRankTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('careerRankings').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final rating = (snapshot.data?.data()?['eloRating'] as num?)?.toInt();
        if (rating == null) return const SizedBox.shrink();
        return FutureBuilder<AggregateQuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('careerRankings')
              .where('eloRating', isGreaterThan: rating)
              .count()
              .get(),
          builder: (context, countSnapshot) {
            final rank = (countSnapshot.data?.count ?? 0) + 1;
            return GamePanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 14,
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, color: AppColors.brassLight),
                  const SizedBox(width: 10),
                  Text(S.f('season_rank_label', [rank]), style: TextStyle(color: AppColors.canvas)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RecentMatchesList extends StatelessWidget {
  final String uid;

  const _RecentMatchesList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('players', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final finished = snapshot.data!.docs.where((doc) => doc.data()['status'] == 'finished').toList();
        if (finished.isEmpty) {
          return Text(
            S.t('recent_matches_empty'),
            style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.6)),
          );
        }
        return GamePanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: 14,
          child: Column(
            children: [
              for (var i = 0; i < finished.length; i++) ...[
                if (i > 0) const Divider(color: Colors.white24, height: 16),
                _RecentMatchRow(uid: uid, data: finished[i].data()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _RecentMatchRow({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final winnerUid = data['winnerUid'] as String?;
    final formats = List<String>.from(data['formats'] as List? ?? []);

    final String label;
    final Color color;
    final IconData icon;
    if (winnerUid == null) {
      label = S.t('recent_match_draw');
      color = Colors.grey.shade400;
      icon = Icons.remove;
    } else if (winnerUid == uid) {
      label = S.t('recent_match_win');
      color = Colors.greenAccent.shade400;
      icon = Icons.emoji_events;
    } else {
      label = S.t('recent_match_loss');
      color = AppColors.signalRed;
      icon = Icons.close;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          if (formats.isNotEmpty)
            Flexible(
              child: Text(
                formats.map((f) => gameFormatById(f).displayName).join(' · '),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColors.canvas.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}
