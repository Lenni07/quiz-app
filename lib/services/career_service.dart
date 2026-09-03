import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/career_ranking_entry.dart';

/// Karriere-Rangliste (siehe ROADMAP_QuizApp.md Abschnitt 15/16). Die
/// ELO-Wertung selbst wird ausschließlich von den 1-vs-1-Match-Cloud-
/// Functions geschrieben (siehe career_match_service.dart) - dieser Dienst
/// liest hier nur.
class CareerService {
  CareerService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
