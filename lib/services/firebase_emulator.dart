import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Schalter für den lokalen Firebase-Emulator (siehe ROADMAP_QuizApp.md
/// Abschnitt 18h). Standardmäßig AUS - die App spricht dann wie bisher die
/// echte Firebase-Umgebung an. Zum Testen gegen den Emulator die App mit
///
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
///   flutter build web --dart-define=USE_FIREBASE_EMULATOR=true
///
/// starten. Der Wert wird beim Kompilieren fest eingebacken, kann also nicht
/// versehentlich in einem echten Release landen.
const bool useFirebaseEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

/// Adresse, unter der die Emulatoren laufen. `localhost` passt für die
/// Web-Version und Desktop. Ein echtes Android-Gerät / der Android-Emulator
/// bräuchte stattdessen die Host-IP bzw. `10.0.2.2` - das kommt erst, wenn
/// wir den Android-Login angehen (18h, späterer Teil).
const String _emulatorHost = 'localhost';

// Ports aus firebase.json (Abschnitt "emulators").
const int _authPort = 9099;
const int _firestorePort = 8090;
const int _functionsPort = 5001;

// Muss zur Region in den Cloud Functions passen (functions/index.js:
// setGlobalOptions({ region: "europe-west3" })).
const String functionsRegion = 'europe-west3';

/// Verbindet Auth, Firestore und Functions mit dem lokalen Emulator - aber
/// nur, wenn [useFirebaseEmulator] gesetzt ist. Muss nach
/// `Firebase.initializeApp` und vor dem ersten Login/DB-Zugriff laufen.
Future<void> connectToFirebaseEmulatorsIfEnabled() async {
  if (!useFirebaseEmulator) return;

  debugPrint('Firebase: connecting to local emulators at $_emulatorHost');
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, _authPort);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, _firestorePort);
  FirebaseFunctions.instanceFor(region: functionsRegion)
      .useFunctionsEmulator(_emulatorHost, _functionsPort);
}
