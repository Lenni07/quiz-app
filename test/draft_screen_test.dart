// Tests für den 1-vs-1-Draft-Bildschirm (siehe draft_screen.dart und
// ROADMAP_QuizApp.md Abschnitt 17 / 18h-Kontext).
//
// 1. Frühere Endlosschleife: _handleUpdate wurde aus dem StreamBuilder im
//    build() aufgerufen -> setState während build -> Frame baut sich endlos
//    selbst neu (im Release-Build ein harter Freeze). Regression bleibt
//    abgedeckt.
// 2. Frist-Ablauf: läuft die Zug-Frist ab, bittet der Client den Server
//    (advanceDraftIfExpired) um eine Auto-Aktion - AUCH wenn ein abwesender
//    Gegner am Zug ist. Genau diesen Fall hat der alte Test nicht erfasst
//    (turnDeadline lag dort 60s in der Zukunft).
// 3. Abgebrochenes Match: status "aborted" -> Hinweisdialog.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/screens/draft_screen.dart';
import 'package:rank_up/services/career_match_service.dart';

/// Zeichnet die Server-Aufrufe auf, statt echte Cloud Functions zu rufen.
class _RecordingService extends CareerMatchService {
  _RecordingService(FakeFirebaseFirestore firestore) : super(firestore: firestore);

  int advanceCalls = 0;
  final List<String> draftActions = [];

  @override
  Future<void> advanceDraftIfExpired(String matchId) async {
    advanceCalls++;
  }

  @override
  Future<void> submitDraftAction({required String matchId, required String formatId}) async {
    draftActions.add(formatId);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _RecordingService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = _RecordingService(firestore);
  });

  Map<String, dynamic> draftDoc({
    int draftStep = 0,
    String status = 'drafting',
    String turnUid = 'opponent',
    int deadlineOffsetMs = 60000,
  }) =>
      {
        'players': const ['me', 'opponent'],
        'status': status,
        'pool': const ['allgemeinwissen-quiz', 'wahr-oder-falsch', 'bild-quiz', 'open-the-box'],
        'banned': const <String>[],
        'picks': const <String, dynamic>{},
        'draftStep': draftStep,
        'turnUid': turnUid,
        'turnDeadline': DateTime.now().millisecondsSinceEpoch + deadlineOffsetMs,
      };

  testWidgets('ein Draft-Snapshot löst keine Build-Endlosschleife aus', (tester) async {
    await firestore.collection('matches').doc('m1').set(draftDoc());

    await tester.pumpWidget(MaterialApp(home: DraftScreen(matchId: 'm1', service: service)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('egner'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('viele schnelle Draft-Updates hintereinander bleiben stabil', (tester) async {
    final ref = firestore.collection('matches').doc('m2');
    await ref.set(draftDoc());

    await tester.pumpWidget(MaterialApp(home: DraftScreen(matchId: 'm2', service: service)));
    await tester.pump();

    for (var step = 1; step <= 6; step++) {
      await ref.update(draftDoc(draftStep: step));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('abgelaufene Frist beim ABWESENDEN Gegner -> Client bittet Server um Auto-Aktion',
      (tester) async {
    // Gegner ist am Zug, Frist schon abgelaufen (deadline in der Vergangenheit).
    await firestore.collection('matches').doc('m3').set(
          draftDoc(turnUid: 'opponent', deadlineOffsetMs: -2000),
        );

    await tester.pumpWidget(MaterialApp(home: DraftScreen(matchId: 'm3', service: service)));
    await tester.pump(); // erster Snapshot + sofortiger tick()
    await tester.pump(const Duration(seconds: 1));

    expect(service.advanceCalls, greaterThanOrEqualTo(1));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('abgelaufene Frist wird nur gedrosselt an den Server gemeldet', (tester) async {
    await firestore.collection('matches').doc('m4').set(
          draftDoc(turnUid: 'me', deadlineOffsetMs: -5000),
        );

    await tester.pumpWidget(MaterialApp(home: DraftScreen(matchId: 'm4', service: service)));
    await tester.pump();
    // 3 Ticks innerhalb von 3s -> Drosselung (4s) lässt nur einen Aufruf durch.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(service.advanceCalls, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('status "aborted" zeigt den Abbruch-Hinweis', (tester) async {
    final ref = firestore.collection('matches').doc('m5');
    await ref.set(draftDoc());

    await tester.pumpWidget(MaterialApp(home: DraftScreen(matchId: 'm5', service: service)));
    await tester.pump();

    await ref.update({'status': 'aborted', 'abortReason': 'opponent_unresponsive'});
    await tester.pump();
    await tester.pump();

    expect(find.text('Match abgebrochen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
