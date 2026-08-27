// Prüft lib/services/fleet_war_service.dart gegen eine simulierte Firestore-
// Datenbank (kein echtes Firebase nötig). Die eigentliche Punkte-Addition
// passiert serverseitig in functions/index.js (dort per Firebase-Emulator-
// Suite manuell getestet, siehe Commit-Nachricht) - hier wird nur geprüft,
// dass der App-Code die richtigen Collections/Felder anspricht.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/fleet_war_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FleetWarService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FleetWarService(firestore: firestore);
  });

  test('joinShip speichert die normierte Schiffs-ID im Nutzerprofil', () async {
    await service.joinShip(uid: 'user-1', shipName: '  MS Freedom  ');

    final userDoc = await firestore.collection('users').doc('user-1').get();
    expect(userDoc.data()?['ship'], 'ms-freedom');
    expect(userDoc.data()?['shipDisplayName'], 'MS Freedom');

    expect(await service.currentShip('user-1'), 'ms-freedom');
  });

  test('submitScore legt eine scoreSubmission mit den richtigen Feldern an', () async {
    await service.joinShip(uid: 'user-1', shipName: 'MS Freedom');
    await service.submitScore(uid: 'user-1', score: 6, total: 8);

    final submissions = await firestore.collection('scoreSubmissions').get();
    expect(submissions.docs.length, 1);
    final data = submissions.docs.first.data();
    expect(data['uid'], 'user-1');
    expect(data['shipId'], 'ms-freedom');
    expect(data['score'], 6);
    expect(data['total'], 8);
  });

  test('submitScore ohne Schiff schreibt keine Einreichung', () async {
    await service.submitScore(uid: 'user-ohne-schiff', score: 3, total: 8);

    final submissions = await firestore.collection('scoreSubmissions').get();
    expect(submissions.docs, isEmpty);
  });

  test('watchLeaderboard liefert Schiffe absteigend nach Punktestand', () async {
    await firestore.collection('ships').doc('ms-freedom').set({'name': 'MS Freedom', 'seasonScore': 12});
    await firestore.collection('ships').doc('ms-sun').set({'name': 'MS Sun', 'seasonScore': 30});

    final ships = await service.watchLeaderboard().first;

    expect(ships.map((s) => s.id), ['ms-sun', 'ms-freedom']);
    expect(ships.first.seasonScore, 30);
  });
}
