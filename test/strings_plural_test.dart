// Test für S.plural() (siehe ROADMAP_QuizApp.md Abschnitt 18e, Nachbesserung
// "1 Tage" -> "1 Tag"): korrekte Singular-/Pluralwahl in beiden Sprachen,
// auch wenn die Pluralform von einem anderen Platzhalter abhängt als dem
// Zähl-Argument selbst (z. B. Lernfortschritt: "von {1} Fragen").
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/app_language.dart';
import 'package:rank_up/l10n/strings.dart';

void main() {
  setUp(() => appLanguage.value = AppLanguage.de);
  tearDown(() => appLanguage.value = AppLanguage.de);

  test('Singular bei genau 1, Plural sonst (auch bei 0) - Deutsch', () {
    expect(S.plural('streak_label', 1), '1 Tag');
    expect(S.plural('streak_label', 2), '2 Tage');
    expect(S.plural('streak_label', 0), '0 Tage');
  });

  test('Singular bei genau 1, Plural sonst - Englisch', () {
    appLanguage.value = AppLanguage.en;
    expect(S.plural('streak_label', 1), '1 day');
    expect(S.plural('streak_label', 5), '5 days');
  });

  test('Tages-Challenge-Meldung dekliniert "Tag"/"Tage" korrekt', () {
    expect(S.plural('daily_challenge_streak', 1), contains('1 Tag in Folge'));
    expect(S.plural('daily_challenge_streak', 1), isNot(contains('1 Tage')));
    expect(S.plural('daily_challenge_streak', 3), contains('3 Tage in Folge'));
  });

  test('Fortschrittsanzeige richtet die Pluralform nach der Gesamtzahl (zweiter Platzhalter)', () {
    // 1 von 1 Frage sicher (Singular, obwohl das erste Argument auch 1 ist).
    expect(S.plural('progress_level_detail', 1, [1, 1]), '1 von 1 Frage sicher');
    // 0 von 1 Frage sicher (Singular, weil die Gesamtzahl 1 ist).
    expect(S.plural('progress_level_detail', 1, [0, 1]), '0 von 1 Frage sicher');
    // 1 von 3 Fragen sicher (Plural, weil die Gesamtzahl 3 ist).
    expect(S.plural('progress_level_detail', 3, [1, 3]), '1 von 3 Fragen sicher');
  });
}
