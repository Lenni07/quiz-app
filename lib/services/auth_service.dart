import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_emulator.dart';

/// Ausgang eines E-Mail-Link-Anmeldeversuchs (siehe ROADMAP_QuizApp.md
/// Abschnitt 18h). [needsEmail] tritt auf, wenn der Link auf einem anderen
/// Gerät geöffnet wird als angefordert - dann kennt die App die Adresse
/// nicht und muss sie erfragen.
enum EmailLinkOutcome { linkedAnonymous, signedIn, signedInExisting, needsEmail, invalidLink }

/// Anmeldung (siehe ROADMAP_QuizApp.md Abschnitt 18h). Ein anonymes Konto
/// kann per Verknüpfung in ein vollwertiges umgewandelt werden - die Kennung
/// (UID) und damit der gesamte Fortschritt bleiben erhalten. Zwei Wege:
/// Google (Web-Popup) und E-Mail-Link ohne Passwort (vor allem für
/// iPhone-Nutzer ohne Google-Konto).
class AuthService {
  // Erst bei Bedarf auflösen - so lässt sich AuthService in Widget-Tests
  // ohne initialisiertes Firebase konstruieren (siehe FullAccountGate).
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Merkt sich lokal, an welche Adresse gerade ein Anmeldelink ging, damit
  /// der Klick auf den Link (gleiches Gerät) sie nicht erneut abfragen muss.
  static const _pendingEmailKey = 'auth_email_link_email';

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
  /// anonym (weder Google noch E-Mail verknüpft). Robust gegen "Firebase
  /// nicht erreichbar" (offline / im Test) - liefert dann `false`.
  bool get isFullAccount {
    try {
      final user = _auth.currentUser;
      return user != null && !user.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// E-Mail des verknüpften Kontos (Google oder E-Mail-Link) - für die
  /// Anzeige im Profil.
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

  // --- E-Mail-Link-Anmeldung (ROADMAP_QuizApp.md Abschnitt 18h) ---

  /// Schickt einen Anmeldelink an [email] (kein Passwort). Der Link führt
  /// zurück in die App; dort schließt [completeEmailLinkSignIn] die
  /// Anmeldung ab.
  Future<void> sendSignInLinkToEmail(String email) async {
    final trimmed = email.trim();
    await _auth.sendSignInLinkToEmail(
      email: trimmed,
      actionCodeSettings: ActionCodeSettings(
        url: _emailLinkContinueUrl(),
        handleCodeInApp: true,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, trimmed);
  }

  /// Ob [link] ein Firebase-Anmeldelink ist.
  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  /// Die lokal gemerkte Adresse eines noch offenen Link-Versuchs (`null`,
  /// wenn keiner offen ist oder der Link auf einem anderen Gerät geöffnet
  /// wurde).
  Future<String?> pendingEmailLinkAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pendingEmailKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }

  /// Schließt die Anmeldung über den angeklickten [link] ab. [email] muss
  /// mitgegeben werden, wenn der Link auf einem ANDEREN Gerät geöffnet wird
  /// als angefordert - dann steht die Adresse nicht lokal.
  ///
  /// - anonymes Konto  -> Verknüpfung (UID + Fortschritt bleiben)
  /// - E-Mail hat schon ein Konto -> Wechsel in dieses Konto (wie bei Google
  ///   mit `credential-already-in-use`)
  Future<EmailLinkOutcome> completeEmailLinkSignIn(String link, {String? email}) async {
    final resolved = resolveEmailForLink(override: email, stored: await pendingEmailLinkAddress());
    if (resolved == null) return EmailLinkOutcome.needsEmail;

    final credential = EmailAuthProvider.credentialWithLink(email: resolved, emailLink: link);
    final user = _auth.currentUser;
    try {
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
        await user.reload();
        await _clearPendingEmail();
        return EmailLinkOutcome.linkedAnonymous;
      }
      await _auth.signInWithCredential(credential);
      await _clearPendingEmail();
      return EmailLinkOutcome.signedIn;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        await _auth.signInWithCredential(credential);
        await _clearPendingEmail();
        return EmailLinkOutcome.signedInExisting;
      }
      if (e.code == 'invalid-email' ||
          e.code == 'invalid-action-code' ||
          e.code == 'expired-action-code') {
        return EmailLinkOutcome.invalidLink;
      }
      rethrow;
    }
  }

  /// Rückgabeadresse für den Anmeldelink. Nur Web: die aktuelle Herkunft
  /// (z. B. `https://quiz-up-c1312.web.app/`), im Emulator `http://localhost`.
  String _emailLinkContinueUrl() {
    final origin = Uri.base.origin;
    return origin.isEmpty ? 'http://localhost' : '$origin/';
  }

  // --- Abmelden / Konto wechseln (ROADMAP_QuizApp.md Abschnitt 18h) ---

  /// Meldet ab und startet sofort ein frisches anonymes Konto, damit der
  /// Lernmodus weiter nutzbar bleibt. Der Fortschritt des abgemeldeten
  /// Kontos bleibt an dessen Kennung und kommt beim erneuten Anmelden zurück.
  Future<User> signOutToAnonymous() async {
    await _auth.signOut();
    return ensureSignedIn();
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

/// Welche Adresse für den Link-Abschluss gilt: die vom Nutzer erneut
/// eingegebene [override] hat Vorrang, sonst die lokal gemerkte [stored].
/// `null` bedeutet: nachfragen (Link auf anderem Gerät geöffnet).
String? resolveEmailForLink({String? override, String? stored}) {
  final o = override?.trim() ?? '';
  if (o.isNotEmpty) return o;
  final s = stored?.trim() ?? '';
  if (s.isNotEmpty) return s;
  return null;
}
