import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_emulator.dart';

/// Anmeldung (siehe ROADMAP_QuizApp.md Abschnitt 18h). Bisher: rein anonym.
/// Neu: ein anonymes Konto kann per Google-Verknüpfung in ein vollwertiges
/// Konto umgewandelt werden - die Kennung (UID) und damit der gesamte
/// Fortschritt bleiben dabei erhalten.
class AuthService {
  // Erst bei Bedarf auflösen - so lässt sich AuthService in Widget-Tests
  // ohne initialisiertes Firebase konstruieren (siehe FullAccountGate).
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.userChanges();

  /// Meldet den Nutzer anonym an, falls noch nicht angemeldet.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Noch kein vollwertiges Konto: Nutzer ist gar nicht angemeldet oder nur
  /// anonym (kein Google-Anbieter verknüpft). Robust gegen "Firebase nicht
  /// erreichbar" (offline / im Test) - liefert dann `false`.
  bool get isFullAccount {
    try {
      final user = _auth.currentUser;
      return user != null && user.providerData.any((info) => info.providerId == 'google.com');
    } catch (_) {
      return false;
    }
  }

  /// E-Mail des verknüpften Google-Kontos (für die Anzeige im Profil).
  String? get linkedEmail => _auth.currentUser?.email;

  /// Verknüpft das aktuelle (anonyme) Konto mit einem Google-Konto über das
  /// Browser-Popup. UID und alle Daten bleiben erhalten. Nur Web - der
  /// Android-Weg (google_sign_in) kommt in einem späteren Teil von 18h.
  Future<void> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'Nicht angemeldet.');
    }
    await user.linkWithPopup(GoogleAuthProvider());
    await user.reload();
  }

  /// Löscht das Konto samt aller zugehörigen Daten unwiderruflich (DSGVO,
  /// siehe ROADMAP_QuizApp.md Abschnitt 18i). Die eigentliche Löschung macht
  /// die Cloud Function `deleteAccount`; danach wird lokal abgemeldet, damit
  /// die App sofort wieder beim anonymen Startzustand landet.
  Future<void> deleteAccount() async {
    await FirebaseFunctions.instanceFor(region: functionsRegion)
        .httpsCallable('deleteAccount')
        .call();
    try {
      await _auth.signOut();
    } catch (_) {
      // Konto ist serverseitig schon weg - lokaler Abmelde-Fehler egal.
    }
  }

  /// NUR für den lokalen Emulator (siehe firebase_emulator.dart): verknüpft
  /// mit einem Fake-Google-Token ohne echtes Popup, damit Abschnitt 18h
  /// automatisiert im Emulator getestet werden kann. In echten Builds ist
  /// [useFirebaseEmulator] fest `false`, dieser Pfad also nie erreichbar.
  Future<void> debugLinkGoogleForEmulator(String email) async {
    assert(useFirebaseEmulator, 'nur mit laufendem Emulator erlaubt');
    final user = _auth.currentUser!;
    final fakeIdToken = jsonEncode({
      'sub': 'google-uid-$email',
      'email': email,
      'email_verified': true,
      'name': email.split('@').first,
    });
    await user.linkWithCredential(GoogleAuthProvider.credential(idToken: fakeIdToken));
    await user.reload();
  }
}
