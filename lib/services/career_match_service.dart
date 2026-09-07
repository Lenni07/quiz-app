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
