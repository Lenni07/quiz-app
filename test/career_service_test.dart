// Prüft lib/services/career_service.dart gegen eine simulierte Firestore-
// Datenbank. Das eigentliche Matchmaking/ELO passiert serverseitig in
// functions/index.js (dort per Firebase-Emulator-Suite getestet, siehe
// Commit-Nachricht) - hier nur, dass der App-Code die richtigen
// Collections/Felder anspricht.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/career_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CareerService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CareerService(firestore: firestore);
  });

  test('currentRating liefert 1000 als Standardwert ohne gespeicherte Wertung', () async {
    await firestore.collection('users').doc('user-1').set({});
    expect(await service.currentRating('user-1'), 1000);
  });

  test('currentRating liefert die gespeicherte ELO-Wertung', () async {
    await firestore.collection('users').doc('user-1').set({'eloRating': 1234});
    expect(await service.currentRating('user-1'), 1234);
  });

  test('watchRanking liefert Spieler absteigend nach Wertung', () async {
    await firestore.collection('careerRankings').doc('user-1').set({'eloRating': 1050, 'nickname': 'Ann'});
    await firestore.collection('careerRankings').doc('user-2').set({'eloRating': 1300, 'nickname': 'Bo'});

    final ranking = await service.watchRanking().first;

    expect(ranking.map((e) => e.uid), ['user-2', 'user-1']);
    expect(ranking.first.eloRating, 1300);
  });

  test('watchRanking blendet Eintraege ohne Nickname aus', () async {
    await firestore.collection('careerRankings').doc('named').set({'eloRating': 1100, 'nickname': 'Kim'});
    await firestore.collection('careerRankings').doc('nameless').set({'eloRating': 1400});
    await firestore.collection('careerRankings').doc('blank').set({'eloRating': 1500, 'nickname': '  '});

    final ranking = await service.watchRanking().first;

    expect(ranking.map((e) => e.uid), ['named']);
  });
}
