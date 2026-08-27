import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Legt beim ersten Start ein Nutzer-Dokument an (Fortschritt/Schiff kommen
  /// in späteren Schritten dazu, siehe ROADMAP_QuizApp.md Abschnitt 4/6b).
  Future<void> ensureProfileExists(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'ship': null,
        'eloRating': 1000,
      });
    }
  }
}
