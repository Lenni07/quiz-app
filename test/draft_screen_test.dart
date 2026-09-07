// Regressionstest für den 1-vs-1-Draft-Freeze (siehe draft_screen.dart und
// ROADMAP_QuizApp.md Abschnitt 18h-Kontext).
//
// Der Bug: DraftScreen rief seine Nebenwirkungs-Logik (_handleUpdate ->
// tick() -> setState) direkt aus dem StreamBuilder im build() heraus auf.
// setState während build() markiert das Widget sofort wieder als schmutzig
// -> build() läuft im selben Frame endlos erneut -> der ganze Tab friert
// ein. Im Test-Modus (Assertions aktiv) äußert sich das als FlutterError
// "setState() or markNeedsBuild() called during build".
//
// Diese Tests pumpen den DraftScreen gegen eine simulierte Firestore-DB
// und prüfen, dass ein Draft-Snapshot (auch mehrere schnell nacheinander)
// KEINE solche Endlosschleife auslöst.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/screens/draft_screen.dart';
import 'package:rank_up/services/career_match_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CareerMatchService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CareerMatchService(firestore: firestore);
  });

  Map<String, dynamic> draftDoc({int draftStep = 0}) => {
        'players': ['me', 'opponent'],
        'status': 'drafting',
        'pool': const ['allgemeinwissen-quiz', 'wahr-oder-falsch', 'bild-quiz', 'open-the-box'],
        'banned': const <String>[],
        'picks': const <String, dynamic>{},
        'draftStep': draftStep,
        'turnUid': 'opponent',
        // weit in der Zukunft: der Sekunden-Ticker läuft, löst aber keine
        // Auto-Aktion aus - hier geht es nur um die Render-Schleife.
        'turnDeadline': DateTime.now().millisecondsSinceEpoch + 60000,
      };

  testWidgets('ein Draft-Snapshot löst keine Build-Endlosschleife aus', (tester) async {
    await firestore.collection('matches').doc('m1').set(draftDoc());

    await tester.pumpWidget(MaterialApp(
      home: DraftScreen(matchId: 'm1', service: service),
    ));
    await tester.pump(); // Listener liefert den ersten Snapshot
    await tester.pump(const Duration(seconds: 1)); // ein Ticker-Durchlauf

    expect(tester.takeException(), isNull);
    // Draft-UI ist da (Gegner ist am Zug -> "Gegner bannt ...")
    expect(find.textContaining('egner'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // dispose -> Timer/Listener aus
  });

  testWidgets('viele schnelle Draft-Updates hintereinander bleiben stabil', (tester) async {
    final ref = firestore.collection('matches').doc('m2');
    await ref.set(draftDoc());

    await tester.pumpWidget(MaterialApp(
      home: DraftScreen(matchId: 'm2', service: service),
    ));
    await tester.pump();

    for (var step = 1; step <= 6; step++) {
      await ref.update(draftDoc(draftStep: step));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
