import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ship.dart';

/// Schiff-gegen-Schiff-Rangliste (siehe ROADMAP_QuizApp.md Abschnitt 6).
/// Schreibt nie direkt auf ships/** (das darf laut Firestore-Regeln nur die
/// Cloud Function) - stattdessen wird jedes Ergebnis als eigenes Dokument in
/// scoreSubmissions eingereicht, und eine Cloud Function addiert es zum
/// Punktestand des jeweiligen Schiffs.
class FleetWarService {
  FleetWarService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> currentShip(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['ship'] as String?;
  }

  Future<void> joinShip({required String uid, required String shipName}) async {
    final shipId = shipIdFromName(shipName);
    await _firestore.collection('users').doc(uid).set(
      {'ship': shipId, 'shipDisplayName': shipName.trim()},
      SetOptions(merge: true),
    );
  }

  Stream<List<Ship>> watchLeaderboard() {
    return _firestore
        .collection('ships')
        .orderBy('seasonScore', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ship.fromFirestore(doc.id, doc.data())).toList());
  }

  /// Reicht ein Spielergebnis für den Flottenkrieg ein. Macht nichts, wenn
  /// der Nutzer (noch) keinem Schiff beigetreten ist - Mitmachen ist
  /// optional, kein Modus verlangt es.
  Future<void> submitScore({required String uid, required int score, required int total}) async {
    try {
      final shipId = await currentShip(uid);
      if (shipId == null) return;
      await _firestore.collection('scoreSubmissions').add({
        'uid': uid,
        'shipId': shipId,
        'score': score,
        'total': total,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Kein Internet oder Firebase nicht erreichbar: Spielergebnis zählt
      // dann halt nicht für den Flottenkrieg, blockiert aber nicht die App.
    }
  }
}
