import 'package:cloud_firestore/cloud_firestore.dart';
import 'fleet_war_service.dart';

/// Tages-Challenge mit Streak-Zähler (siehe ROADMAP_QuizApp.md Abschnitt
/// 18c): die erste abgeschlossene Runde eines Tages (egal welches Format)
/// zählt als Tages-Challenge, gibt einen Punkte-Bonus auf den
/// Flottentreffen-Punktestand und verlängert den Streak (aufeinanderfolgende
/// Tage). Bewusst kein eigenes Punktesystem - nutzt die bestehende
/// scoreSubmissions-Infrastruktur, FleetWarService.submitScore() fängt
/// "noch kein Schiff beigetreten" bereits selbst ab (kein Bonus, aber auch
/// kein Fehler).
const int dailyChallengeBonusPoints = 10;

String dailyDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DailyChallengeService {
  DailyChallengeService({FirebaseFirestore? firestore, FleetWarService? fleetWarService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _fleetWarService = fleetWarService ?? FleetWarService();

  final FirebaseFirestore _firestore;
  final FleetWarService _fleetWarService;

  /// Zählt eine abgeschlossene Runde als heutige Tages-Challenge, falls
  /// heute noch nicht geschehen. Gibt den neuen Streak zurück, oder null,
  /// wenn heute schon erledigt (kein zweiter Bonus am selben Tag). [now] ist
  /// für Tests da, damit die Streak-Logik ohne echten Tageswechsel geprüft
  /// werden kann - Standard ist die echte aktuelle Zeit.
  Future<int?> recordCompletion(String uid, {DateTime? now}) async {
    try {
      now ??= DateTime.now();
      final today = dailyDateKey(now);
      final yesterday = dailyDateKey(now.subtract(const Duration(days: 1)));

      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      final existing = doc.data()?['dailyChallenge'] as Map<String, dynamic>?;
      final lastDate = existing?['lastCompletedDate'] as String?;
      if (lastDate == today) return null;

      final previousStreak = (existing?['streak'] as num?)?.toInt() ?? 0;
      final newStreak = lastDate == yesterday ? previousStreak + 1 : 1;

      await docRef.set({
        'dailyChallenge': {'lastCompletedDate': today, 'streak': newStreak},
      }, SetOptions(merge: true));

      await _fleetWarService.submitScore(uid: uid, score: dailyChallengeBonusPoints, total: dailyChallengeBonusPoints);

      return newStreak;
    } catch (_) {
      // Kein Internet oder Firebase nicht erreichbar: Streak zählt dann halt
      // nicht für heute, blockiert aber nicht die App.
      return null;
    }
  }
}
