// Prüft personalizationProfileFromUserData (siehe user_profile_service.dart):
// seit ROADMAP_QuizApp.md Abschnitt 18h ist der Vorname ein eigenes,
// sperrfrist-geschütztes Feld (firstName) - nicht mehr aus realName abgeleitet.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/services/user_profile_service.dart';

void main() {
  test('nimmt den Vornamen aus dem firstName-Feld', () {
    final profile = personalizationProfileFromUserData({
      'firstName': 'Lena',
      'realName': 'Ganz Anderer Name',
      'position': 'Kellnerin',
      'grammaticalForm': 'female',
      'birthDate': Timestamp.fromDate(DateTime(2000, 1, 1)),
    });

    expect(profile.firstName, 'Lena');
    expect(profile.position, 'Kellnerin');
    expect(profile.grammaticalForm, 'female');
    expect(profile.age, isNotNull);
  });

  test('fehlender Vorname -> leer (Vorlage wird dann ausgefiltert)', () {
    final profile = personalizationProfileFromUserData({'position': 'Koch'});
    expect(profile.firstName, '');
    expect(profile.age, isNull);
  });

  test('verträgt null', () {
    final profile = personalizationProfileFromUserData(null);
    expect(profile.firstName, '');
  });
}
