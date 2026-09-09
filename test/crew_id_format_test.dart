// Crew-ID-Format: genau 6 Ziffern (siehe ROADMAP_QuizApp.md Abschnitt 18h).
// Dieselbe Prüfung läuft serverseitig in functions/index.js (isValidCrewId),
// damit sie nicht über einen manipulierten Client umgangen werden kann.
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/crew_id_service.dart';

void main() {
  test('genau 6 Ziffern ist gültig', () {
    expect(isValidCrewId('123456'), isTrue);
    expect(isValidCrewId('000000'), isTrue);
  });

  test('Leerzeichen und Bindestriche werden vor der Prüfung entfernt', () {
    expect(isValidCrewId('12 34 56'), isTrue);
    expect(isValidCrewId('123-456'), isTrue);
    expect(isValidCrewId('  654321  '), isTrue);
  });

  test('zu kurz / zu lang ist ungültig', () {
    expect(isValidCrewId('12345'), isFalse);
    expect(isValidCrewId('1234567'), isFalse);
    expect(isValidCrewId(''), isFalse);
  });

  test('Buchstaben oder Sonderzeichen sind ungültig', () {
    expect(isValidCrewId('12345A'), isFalse);
    expect(isValidCrewId('CR1234'), isFalse);
    expect(isValidCrewId('12.345'), isFalse);
  });

  test('normalizeCrewId entfernt nur Leerzeichen und Bindestriche', () {
    expect(normalizeCrewId('12 34-56'), '123456');
    expect(normalizeCrewId('123456'), '123456');
  });
}
