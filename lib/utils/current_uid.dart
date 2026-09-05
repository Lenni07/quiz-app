import 'package:firebase_auth/firebase_auth.dart';

/// Aktuelle Nutzer-ID, robust gegen "Firebase nicht erreichbar" (offline
/// oder z. B. im Test) - liefert dann einfach `null` statt zu werfen.
String? currentUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
