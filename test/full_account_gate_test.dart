// Entscheidungslogik der Konto-Sperre (siehe lib/widgets/full_account_gate.dart
// und ROADMAP_QuizApp.md Abschnitt 18h "Gestufter Zugang").
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/widgets/full_account_gate.dart';

void main() {
  test('kein uid (offline / nicht angemeldet) -> noConnection', () {
    expect(
      gateStateFor(uid: null, isFullAccount: false, crewIdLoaded: false, crewIdSet: false),
      GateState.noConnection,
    );
  });

  test('Firestore-Fehler -> noConnection', () {
    expect(
      gateStateFor(uid: 'u1', isFullAccount: true, crewIdLoaded: true, crewIdSet: true, firestoreError: true),
      GateState.noConnection,
    );
  });

  test('angemeldet, aber anonym (kein Google) -> needsGoogle', () {
    expect(
      gateStateFor(uid: 'u1', isFullAccount: false, crewIdLoaded: true, crewIdSet: false),
      GateState.needsGoogle,
    );
  });

  test('Google da, aber Crew-ID fehlt -> needsCrewId', () {
    expect(
      gateStateFor(uid: 'u1', isFullAccount: true, crewIdLoaded: true, crewIdSet: false),
      GateState.needsCrewId,
    );
  });

  test('Google + Crew-ID -> open', () {
    expect(
      gateStateFor(uid: 'u1', isFullAccount: true, crewIdLoaded: true, crewIdSet: true),
      GateState.open,
    );
  });

  test('Crew-ID-Status noch nicht geladen -> open (Ladeanzeige übernimmt das Widget)', () {
    expect(
      gateStateFor(uid: 'u1', isFullAccount: true, crewIdLoaded: false, crewIdSet: false),
      GateState.open,
    );
  });
}
