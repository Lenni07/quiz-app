import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_emulator.dart';

/// Vereinheitlicht eine Crew-ID-Eingabe: Leerzeichen und Bindestriche raus.
/// Muss zu `normalizeCrewId` in functions/index.js passen (dort zusätzlich
/// `toUpperCase`, was bei reinen Ziffern nichts ändert).
String normalizeCrewId(String raw) => raw.replaceAll(RegExp(r'[\s-]'), '');

/// Gültiges Crew-ID-Format: genau 6 Ziffern (siehe ROADMAP_QuizApp.md
/// Abschnitt 18h). Serverseitig in `claimCrewId` identisch erzwungen, damit
/// die Prüfung nicht über einen manipulierten Client umgangen werden kann.
bool isValidCrewId(String raw) => RegExp(r'^\d{6}$').hasMatch(normalizeCrewId(raw));

/// Crew-ID serverseitig einreichen (siehe ROADMAP_QuizApp.md Abschnitt
/// 18h/18i). Der Client schickt die Crew-ID im Klartext über die
/// verschlüsselte Verbindung; die Cloud Function `claimCrewId` hasht sie
/// (HMAC mit Server-Pepper) und speichert NUR den Hash. Es wird bewusst
/// nichts lokal gespeichert.
class CrewIdService {
  CrewIdService({FirebaseFunctions? functions}) : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Ordnet dem eigenen Konto die [crewId] zu. Wirft:
  /// - [CrewIdTakenException] wenn die ID schon einem anderen Konto gehört
  /// - [CrewIdNeedsGoogleException] wenn das Konto noch anonym ist
  /// - [CrewIdInvalidException] wenn die Eingabe kein gültiges Format hat
  Future<void> claim(String crewId) async {
    try {
      await _functions.httpsCallable('claimCrewId').call({'crewId': crewId});
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'already-exists':
          throw CrewIdTakenException();
        case 'failed-precondition':
          throw CrewIdNeedsGoogleException();
        case 'invalid-argument':
          throw CrewIdInvalidException();
        default:
          rethrow;
      }
    }
  }
}

class CrewIdTakenException implements Exception {}

class CrewIdNeedsGoogleException implements Exception {}

class CrewIdInvalidException implements Exception {}
