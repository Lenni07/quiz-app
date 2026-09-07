// Prüft den Wiedereinstiegs-Bildschirm (siehe match_resume_screen.dart und
// ROADMAP_QuizApp.md Abschnitt 17): abgebrochenes Match zeigt einen Hinweis,
// und bei abgelaufener Runden-Frist bittet der anwesende Spieler den Server
// um die Auswertung (claimRoundTimeout).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/screens/match_resume_screen.dart';
import 'package:rank_up/services/career_match_service.dart';

class _RecordingService extends CareerMatchService {
  _RecordingService(FakeFirebaseFirestore firestore) : super(firestore: firestore);

  int roundTimeoutCalls = 0;

  @override
  Future<void> claimRoundTimeout(String matchId) async {
    roundTimeoutCalls++;
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _RecordingService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = _RecordingService(firestore);
  });

  testWidgets('abgebrochenes Match zeigt den Hinweis', (tester) async {
    await firestore.collection('matches').doc('m1').set({
      'players': ['me', 'other'],
      'status': 'aborted',
      'abortReason': 'both_left',
    });

    await tester.pumpWidget(MaterialApp(home: MatchResumeScreen(matchId: 'm1', service: service)));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('ausgestiegen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Spielphase, eigene Runde eingereicht, Frist abgelaufen -> claimRoundTimeout',
      (tester) async {
    await firestore.collection('matches').doc('m2').set({
      'players': ['me', 'other'],
      'status': 'playing',
      'formats': ['wahr-oder-falsch', 'bild-quiz', 'open-the-box'],
      'currentRound': 0,
      // in einem Test liefert currentUid() null -> _myUid == '' ; also unter
      // dem leeren Schlüssel "einreichen", damit "ich habe schon eingereicht"
      // greift und die Warteansicht (mit Timeout-Ticker) erscheint.
      'roundScores': {
        '0': {'': {'score': 3, 'total': 5}}
      },
      'roundWinners': [null, null, null],
      'roundDeadline': DateTime.now().millisecondsSinceEpoch - 20000,
    });

    await tester.pumpWidget(MaterialApp(home: MatchResumeScreen(matchId: 'm2', service: service)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // ein Ticker-Durchlauf

    expect(service.roundTimeoutCalls, greaterThanOrEqualTo(1));

    await tester.pumpWidget(const SizedBox());
  });
}
