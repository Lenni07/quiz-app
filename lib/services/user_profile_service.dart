import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar_option.dart';
import '../models/personalized_question.dart';

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
        'rankedMatchesPlayed': 0,
        'nickname': null,
        'realName': null,
        'position': null,
        'department': null,
        'avatarId': allAvatarOptions.first.id,
        'crewId': null,
        'germanLevel': null,
        'certificateIssuedAt': null,
        'birthDate': null,
        'grammaticalForm': null,
      });
    }
  }

  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Speichert die Profilangaben aus ROADMAP_QuizApp.md Abschnitt 18
  /// (Nickname/Position sind auch in der Rangliste sichtbar, alles andere
  /// bleibt nur im eigenen Profil). Das Deutsch-Level hat seit Abschnitt 18b
  /// keinen Einfluss mehr auf Wertung/Matchmaking - reine Profil-Information.
  /// eloRating wird hier bewusst NICHT geschrieben, das ist per Regel
  /// ohnehin nur den Cloud Functions erlaubt.
  Future<void> updateProfile({
    required String uid,
    required String nickname,
    required String realName,
    required String position,
    required String department,
    required String avatarId,
    required String crewId,
    required int? germanLevel,
    required DateTime? certificateIssuedAt,
    required DateTime? birthDate,
    required String? grammaticalForm,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'nickname': nickname,
      'realName': realName,
      'position': position,
      'department': department,
      'avatarId': avatarId,
      'crewId': crewId,
      'germanLevel': germanLevel,
      'certificateIssuedAt': certificateIssuedAt == null ? null : Timestamp.fromDate(certificateIssuedAt),
      'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate),
      'grammaticalForm': grammaticalForm,
    }, SetOptions(merge: true));
  }
}

/// Wandelt die in Firestore gespeicherten Profil-Rohdaten in die
/// Firebase-unabhängigen [PersonalizationProfile]-Werte um (siehe
/// ROADMAP_QuizApp.md Abschnitt 18f) - der Vorname wird bewusst aus dem
/// vorhandenen "echter Name"-Feld abgeleitet (erstes Wort), statt ein
/// weiteres Profilfeld nur dafür einzuführen.
PersonalizationProfile personalizationProfileFromUserData(Map<String, dynamic>? data) {
  final realName = (data?['realName'] as String?)?.trim() ?? '';
  final firstName = realName.isEmpty ? '' : realName.split(RegExp(r'\s+')).first;
  final birthDate = (data?['birthDate'] as Timestamp?)?.toDate();

  return PersonalizationProfile(
    firstName: firstName,
    age: birthDate == null ? null : calculateAge(birthDate),
    position: (data?['position'] as String?)?.trim() ?? '',
    crewId: (data?['crewId'] as String?)?.trim() ?? '',
    grammaticalForm: data?['grammaticalForm'] as String?,
  );
}
