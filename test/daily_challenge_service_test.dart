// Prüft lib/services/daily_challenge_service.dart gegen eine simulierte
// Firestore-Datenbank (siehe ROADMAP_QuizApp.md Abschnitt 18c).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/daily_challenge_service.dart';
import 'package:rank_up/services/fleet_war_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DailyChallengeService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = DailyChallengeService(firestore: firestore, fleetWarService: FleetWarService(firestore: firestore));
  });

  final day1 = DateTime(2026, 9, 10);
  final day2 = day1.add(const Duration(days: 1));
  final dayWithGap = day1.add(const Duration(days: 3));

  test('erste Runde überhaupt: Streak startet bei 1', () async {
    final streak = await service.recordCompletion('user-1', now: day1);
    expect(streak, 1);
    expect((await firestore.collection('users').doc('user-1').get()).data()?['dailyChallenge'], {
      'lastCompletedDate': '2026-09-10',
      'streak': 1,
    });
  });

  test('zweite Runde am selben Tag: kein zweiter Bonus, gibt null zurück', () async {
    await service.recordCompletion('user-1', now: day1);
    final second = await service.recordCompletion('user-1', now: day1);
    expect(second, isNull);
  });

  test('Runde am Folgetag: Streak verlängert sich', () async {
    await service.recordCompletion('user-1', now: day1);
    final streak = await service.recordCompletion('user-1', now: day2);
    expect(streak, 2);
  });

  test('Runde nach einer Lücke: Streak setzt auf 1 zurück', () async {
    await service.recordCompletion('user-1', now: day1);
    final streak = await service.recordCompletion('user-1', now: dayWithGap);
    expect(streak, 1);
  });

  test('mit Schiff: Bonus wird als scoreSubmission eingereicht', () async {
    await firestore.collection('users').doc('user-1').set({'ship': 'ms-freedom'});
    await service.recordCompletion('user-1', now: day1);

    final submissions = await firestore.collection('scoreSubmissions').where('uid', isEqualTo: 'user-1').get();
    expect(submissions.docs.length, 1);
    expect(submissions.docs.first.data()['score'], dailyChallengeBonusPoints);
  });

  test('ohne Schiff: kein Bonus, aber Streak zählt trotzdem', () async {
    final streak = await service.recordCompletion('user-1', now: day1);
    expect(streak, 1);

    final submissions = await firestore.collection('scoreSubmissions').where('uid', isEqualTo: 'user-1').get();
    expect(submissions.docs, isEmpty);
  });
}
