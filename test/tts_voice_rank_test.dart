// Test für die TTS-Stimmen-Rangfolge (siehe ROADMAP_QuizApp.md Abschnitt
// 18g, kurzfristiger Teil): netzbasierte Google-Stimmen vor anderen Neural-/
// Premium-Stimmen vor der Standard-Systemstimme.
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/utils/tts_voice_rank.dart';

void main() {
  test('Google-Stimmen erhalten den besten Rang (0)', () {
    expect(rankTtsVoiceName('Google Deutsch'), 0);
    expect(rankTtsVoiceName('google deutsch'), 0); // Groß-/Kleinschreibung egal
  });

  test('Andere Neural-/Online-/Premium-Stimmen erhalten Rang 1', () {
    expect(rankTtsVoiceName('Microsoft Katja Online (Natural) - German (Germany)'), 1);
    expect(rankTtsVoiceName('Some Neural Voice'), 1);
    expect(rankTtsVoiceName('Amazon Premium Voice'), 1);
    expect(rankTtsVoiceName('Enhanced Quality Voice'), 1);
  });

  test('Standard-/lokale Stimmen ohne besondere Kennzeichnung erhalten Rang 2', () {
    expect(rankTtsVoiceName('Microsoft Hedda - German (Germany)'), 2);
    expect(rankTtsVoiceName('Anna'), 2);
  });

  test('Sortierung nach Rang bringt Google zuerst, Standard zuletzt', () {
    final names = ['Microsoft Hedda - German', 'Google Deutsch', 'Microsoft Katja Online (Natural)']
      ..sort((a, b) => rankTtsVoiceName(a).compareTo(rankTtsVoiceName(b)));
    expect(names.first, 'Google Deutsch');
    expect(names.last, 'Microsoft Hedda - German');
  });
}
