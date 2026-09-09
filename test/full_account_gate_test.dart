// Entscheidungslogik der Konto-Sperre (siehe lib/widgets/full_account_gate.dart
// und ROADMAP_QuizApp.md Abschnitt 18h "Gestufter Zugang"). Verlangt werden
// Google-Anmeldung, Crew-ID sowie Nickname UND Position (beide stehen in der
// Rangliste).
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/widgets/full_account_gate.dart';

void main() {
  test('kein uid (offline / nicht angemeldet) -> nicht verbunden, gesperrt', () {
    final a = competitiveAccessFor(uid: null, isFullAccount: false, profileLoaded: false);
    expect(a.connected, isFalse);
    expect(a.open, isFalse);
  });

  test('Firestore-Fehler -> nicht verbunden, gesperrt', () {
    final a = competitiveAccessFor(
      uid: 'u1',
      isFullAccount: true,
      profileLoaded: true,
      crewIdSet: true,
      nickname: 'Nic',
      position: 'Kellner',
      firestoreError: true,
    );
    expect(a.connected, isFalse);
    expect(a.open, isFalse);
  });

  test('Profil noch nicht geladen -> vorläufig offen (Ladeanzeige übernimmt das Widget)', () {
    final a = competitiveAccessFor(uid: 'u1', isFullAccount: true, profileLoaded: false);
    expect(a.open, isTrue);
  });

  test('anonym (kein Google) -> gesperrt, google offen', () {
    final a = competitiveAccessFor(
      uid: 'u1',
      isFullAccount: false,
      profileLoaded: true,
      crewIdSet: true,
      nickname: 'Nic',
      position: 'Kellner',
    );
    expect(a.google, isFalse);
    expect(a.open, isFalse);
  });

  test('Google + Crew-ID, aber Nickname fehlt -> gesperrt', () {
    final a = competitiveAccessFor(
      uid: 'u1',
      isFullAccount: true,
      profileLoaded: true,
      crewIdSet: true,
      nickname: '   ',
      position: 'Kellner',
    );
    expect(a.nickname, isFalse);
    expect(a.open, isFalse);
  });

  test('Google + Crew-ID + Nickname, aber Position fehlt -> gesperrt', () {
    final a = competitiveAccessFor(
      uid: 'u1',
      isFullAccount: true,
      profileLoaded: true,
      crewIdSet: true,
      nickname: 'Nic',
      position: null,
    );
    expect(a.position, isFalse);
    expect(a.open, isFalse);
  });

  test('alle vier Voraussetzungen erfüllt -> offen', () {
    final a = competitiveAccessFor(
      uid: 'u1',
      isFullAccount: true,
      profileLoaded: true,
      crewIdSet: true,
      nickname: 'Nic',
      position: 'Kellner',
    );
    expect(a.open, isTrue);
  });
}
