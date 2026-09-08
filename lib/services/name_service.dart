import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_emulator.dart';

/// Vorname und Nickname ändern (siehe ROADMAP_QuizApp.md Abschnitt 18h
/// Punkt 4). Läuft über die Cloud Function `updateLockedNames`, die die
/// 30-Tage-Sperrfrist pro Feld serverseitig durchsetzt - der Client kann
/// die Felder nicht direkt in Firestore schreiben.
class NameService {
  NameService({FirebaseFunctions? functions}) : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Sendet nur die übergebenen Felder. Ein unveränderter Wert ist
  /// serverseitig ein No-Op und stößt die Frist nicht an. Wirft
  /// [NameLockedException] (mit Restdauer) bzw. [NameInvalidException].
  Future<void> updateNames({String? firstName, String? nickname}) async {
    final payload = <String, dynamic>{};
    if (firstName != null) payload['firstName'] = firstName;
    if (nickname != null) payload['nickname'] = nickname;
    if (payload.isEmpty) return;

    try {
      await _functions.httpsCallable('updateLockedNames').call(payload);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        final details = e.details;
        throw NameLockedException(
          daysLeft: details is Map ? (details['daysLeft'] as num?)?.toInt() : null,
          field: details is Map ? details['field'] as String? : null,
        );
      }
      if (e.code == 'invalid-argument') throw NameInvalidException();
      rethrow;
    }
  }
}

class NameLockedException implements Exception {
  final int? daysLeft;
  final String? field;

  NameLockedException({this.daysLeft, this.field});
}

class NameInvalidException implements Exception {}
