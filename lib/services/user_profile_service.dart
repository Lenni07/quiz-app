import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar_option.dart';

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
        'nickname': null,
        'realName': null,
        'position': null,
        'department': null,
        'avatarId': allAvatarOptions.first.id,
      });
    }
  }

  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Speichert die Profilangaben aus ROADMAP_QuizApp.md Abschnitt 18
  /// (Nickname/Position sind auch in der Rangliste sichtbar, echter Name und
  /// Department bleiben nur im eigenen Profil).
  Future<void> updateProfile({
    required String uid,
    required String nickname,
    required String realName,
    required String position,
    required String department,
    required String avatarId,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'nickname': nickname,
      'realName': realName,
      'position': position,
      'department': department,
      'avatarId': avatarId,
    }, SetOptions(merge: true));
  }
}
