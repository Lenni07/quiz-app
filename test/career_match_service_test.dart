// Prüft die Firestore-Abfragen von CareerMatchService gegen eine simulierte
// Datenbank (die Cloud Functions selbst werden per Emulator getestet).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/career_match_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CareerMatchService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = CareerMatchService(firestore: firestore);
  });

  Future<void> addMatch(String id, {required List<String> players, required String status, required int createdAt}) {
    return firestore.collection('matches').doc(id).set({
      'players': players,
      'status': status,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
    });
  }

  group('watchActiveMatch', () {
    test('liefert null, wenn der Nutzer kein laufendes Match hat', () async {
      await addMatch('m1', players: ['me', 'x'], status: 'finished', createdAt: 1000);
      await addMatch('m2', players: ['other', 'y'], status: 'playing', createdAt: 2000);

      expect(await service.watchActiveMatch('me').first, isNull);
    });

    test('liefert das laufende Match (Draft oder Spielphase)', () async {
      await addMatch('done', players: ['me', 'x'], status: 'finished', createdAt: 1000);
      await addMatch('live', players: ['me', 'x'], status: 'playing', createdAt: 3000);

      final doc = await service.watchActiveMatch('me').first;
      expect(doc?.id, 'live');
    });

    test('überspringt beendete Matches auch wenn sie neuer sind', () async {
      await addMatch('drafting', players: ['me', 'x'], status: 'drafting', createdAt: 1000);
      await addMatch('newerFinished', players: ['me', 'x'], status: 'finished', createdAt: 5000);

      final doc = await service.watchActiveMatch('me').first;
      expect(doc?.id, 'drafting');
    });
  });
}
