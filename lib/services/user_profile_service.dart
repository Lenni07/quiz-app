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
        'firstName': null,
        'firstNameChangedAt': null,
        'nickname': null,
        'nicknameChangedAt': null,
        'realName': null,
        'position': null,
        'department': null,
        'avatarId': allAvatarOptions.first.id,
        'crewIdHash': null,
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

  /// Speichert die frei änderbaren Profilangaben. Vorname und Nickname sind
  /// hier NICHT dabei - die laufen wegen der 30-Tage-Sperrfrist über die
  /// Cloud Function (siehe NameService / ROADMAP_QuizApp.md Abschnitt 18h).
  /// eloRating/crewIdHash werden ebenfalls bewusst nicht geschrieben, das ist
  /// per Regel nur den Cloud Functions erlaubt.
  Future<void> updateProfile({
    required String uid,
    required String realName,
    required String position,
    required String department,
    required String avatarId,
    required int? germanLevel,
    required DateTime? certificateIssuedAt,
    required DateTime? birthDate,
    required String? grammaticalForm,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'realName': realName,
      'position': position,
      'department': department,
      'avatarId': avatarId,
      'germanLevel': germanLevel,
      'certificateIssuedAt': certificateIssuedAt == null ? null : Timestamp.fromDate(certificateIssuedAt),
      'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate),
      'grammaticalForm': grammaticalForm,
    }, SetOptions(merge: true));
  }
}

/// Wandelt die in Firestore gespeicherten Profil-Rohdaten in die
/// Firebase-unabhängigen [PersonalizationProfile]-Werte um (siehe
/// ROADMAP_QuizApp.md Abschnitt 18f). Der Vorname ist ein eigenes,
/// serverseitig sperrfrist-geschütztes Feld (Abschnitt 18h).
PersonalizationProfile personalizationProfileFromUserData(Map<String, dynamic>? data) {
  final birthDate = (data?['birthDate'] as Timestamp?)?.toDate();

  return PersonalizationProfile(
    firstName: (data?['firstName'] as String?)?.trim() ?? '',
    age: birthDate == null ? null : calculateAge(birthDate),
    position: (data?['position'] as String?)?.trim() ?? '',
    grammaticalForm: data?['grammaticalForm'] as String?,
  );
}
