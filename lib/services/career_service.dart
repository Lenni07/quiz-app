import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/career_ranking_entry.dart';

/// Karrieremodus-Ranking (siehe ROADMAP_QuizApp.md Abschnitt 15). Schreibt
/// nie direkt eine ELO-Wertung - das darf laut Firestore-Regeln nur die
/// Cloud Function matchCareerSubmission. Der Client reicht nur das rohe
/// Ergebnis ein, das Matchmaking passiert serverseitig.
class CareerService {
  CareerService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submitResult({
    required String uid,
    required String format,
    required int score,
    required int total,
  }) async {
    try {
      await _firestore.collection('careerSubmissions').add({
        'uid': uid,
        'format': format,
        'score': score,
        'total': total,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Kein Internet oder Firebase nicht erreichbar: Runde zählt dann halt
      // nicht fürs Ranking, blockiert aber nicht die App.
    }
  }

  Future<int> currentRating(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['eloRating'] as num?)?.toInt() ?? 1000;
  }

  Stream<List<CareerRankingEntry>> watchRanking() {
    return _firestore
        .collection('careerRankings')
        .orderBy('eloRating', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CareerRankingEntry.fromFirestore(doc.id, doc.data())).toList());
  }
}
