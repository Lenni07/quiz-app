import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 1-vs-1-Live-Matchmaking mit Draft-Phase (siehe ROADMAP_QuizApp.md
/// Abschnitt 16/17). Alle Zustandsänderungen (Matchmaking, Draft-Züge,
/// Rundenergebnisse, ELO) laufen über Cloud Functions - der Client liest
/// nur per Live-Listener mit und schickt Aktionen als Callable-Aufrufe,
/// schreibt aber nie direkt in matches/** (siehe firestore.rules).
class CareerMatchService {
  CareerMatchService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functionsOverride = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functionsOverride;

  // Erst bei Bedarf auflösen - so lässt sich der Dienst in Tests ohne
  // initialisiertes Firebase erzeugen (nur mit einer simulierten Firestore).
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instanceFor(region: 'europe-west3');

  Future<void> joinQueue(String uid) async {
    await _firestore.collection('careerQueue').doc(uid).set({
      'status': 'searching',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelQueue(String uid) async {
    await _firestore.collection('careerQueue').doc(uid).set({'status': 'idle'}, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchQueue(String uid) {
    return _firestore.collection('careerQueue').doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMatch(String matchId) {
    return _firestore.collection('matches').doc(matchId).snapshots();
  }

  Future<void> submitDraftAction({required String matchId, required String formatId}) {
    return _functions
        .httpsCallable('submitDraftAction')
        .call({'matchId': matchId, 'formatId': formatId});
  }

  /// Bittet den Server, bei abgelaufener Zug-Frist eine zufällige Aktion für
  /// den Spieler am Zug zu erzwingen (siehe ROADMAP_QuizApp.md Abschnitt 17).
  /// Der Server prüft die Frist selbst - ruft der anwesende Spieler das auf,
  /// obwohl die Frist doch noch läuft, passiert nichts.
  Future<void> advanceDraftIfExpired(String matchId) {
    return _functions.httpsCallable('advanceDraftIfExpired').call({'matchId': matchId});
  }

  /// Bittet den Server, eine abgelaufene Runden-Frist auszuwerten (siehe
  /// ROADMAP_QuizApp.md Abschnitt 17): hat nur der anwesende Spieler
  /// eingereicht, gewinnt er das Match. Server prüft die Frist selbst.
  Future<void> claimRoundTimeout(String matchId) {
    return _functions.httpsCallable('claimRoundTimeout').call({'matchId': matchId});
  }

  /// Ein laufendes Match dieses Nutzers (Draft oder Spielphase), falls
  /// vorhanden - für den Wiedereinstieg nach einem Verbindungsabriss. Nutzt
  /// denselben Index wie die "letzte Matches"-Liste (players + createdAt);
  /// der Status wird clientseitig gefiltert.
  Stream<DocumentSnapshot<Map<String, dynamic>>?> watchActiveMatch(String uid) {
    return _firestore
        .collection('matches')
        .where('players', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final status = doc.data()['status'];
        if (status == 'drafting' || status == 'playing') return doc;
      }
      return null;
    });
  }

  Future<void> submitRoundResult({
    required String matchId,
    required int roundIndex,
    required int score,
    required int total,
  }) {
    return _functions.httpsCallable('submitRoundResult').call({
      'matchId': matchId,
      'roundIndex': roundIndex,
      'score': score,
      'total': total,
    });
  }
}
