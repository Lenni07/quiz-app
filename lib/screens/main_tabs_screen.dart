import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';
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

  static const _tabIcons = [
    Icons.school_outlined,
    Icons.groups_outlined,
    Icons.sports_martial_arts,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];
  static const _tabLabels = ['Lernmodus', 'Flottentreffen', '1 vs 1', 'Rangliste', 'Profil'];

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
    return Scaffold(
      appBar: _buildHeader(context),
      body: _buildActiveTab(context),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: [
          for (var i = 0; i < _tabIcons.length; i++)
            BottomNavigationBarItem(
              icon: i == 2
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_tabIcons[i], color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : Icon(_tabIcons[i]),
              label: _tabLabels[i],
            ),
        ],
      ),
    );
  }

  Widget _buildOneVsOneLanding(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_martial_arts, size: 72, color: colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              '1 vs 1',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gegner mit ähnlicher Wertung, Draft-Phase, Best of 3.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, buildFadeSlideRoute(const OneVsOneQueueScreen()));
                },
                child: const Text('Kampf starten'),
              ),
            ),
          ],
        ),
      ),
    );
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
          ? const Text('Quiz Up Your Rank')
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final rating = (snapshot.data?.data()?['eloRating'] as num?)?.toInt() ?? 1000;
                final level = rating ~/ 100;
                final progress = (rating % 100) / 100;
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
