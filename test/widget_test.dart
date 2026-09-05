// Einfacher Smoke-Test: Startbildschirm mit "Spiel starten" führt zur
// Reiter-Navigation (siehe ROADMAP_QuizApp.md Abschnitt 16) mit den 5
// Hauptbereichen.
import 'package:flutter_test/flutter_test.dart';

import 'package:rank_up/l10n/app_language.dart';
import 'package:rank_up/main.dart';

void main() {
  testWidgets('Spiel starten führt zur Reiter-Navigation mit allen 5 Bereichen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Quiz Up Your Rank'), findsOneWidget);
    expect(find.text('Spiel starten'), findsOneWidget);

    await tester.tap(find.text('Spiel starten'));
    await tester.pumpAndSettle();

    expect(find.text('Lernmodus'), findsOneWidget);
    expect(find.text('Flottentreffen'), findsOneWidget);
    expect(find.text('1 vs 1'), findsWidgets);
    expect(find.text('Rangliste'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Standardmäßig ist der 1-vs-1-Reiter aktiv (Hauptmodus). Ohne
    // initialisiertes Firebase (wie in diesem Test) zeigt er konsequent
    // dieselbe "keine Verbindung zum Konto"-Meldung wie Profil/Flottentreffen,
    // statt einen Button anzuzeigen, der sowieso fehlschlagen würde.
    expect(find.text('Quiz-Duell starten'), findsNothing);
    expect(find.textContaining('Keine Verbindung zum Konto'), findsOneWidget);

    await tester.tap(find.text('Lernmodus'));
    await tester.pumpAndSettle();

    expect(find.text('Allgemeinwissen-Quiz'), findsOneWidget);
  });

  testWidgets('Sprachwechsel (Abschnitt 19) übersetzt die Bedienoberfläche live, ohne Neustart',
      (WidgetTester tester) async {
    // appLanguage ist global - für diesen Test unabhängig von der
    // Ausführungsreihenfolge sauber auf Deutsch zurücksetzen.
    addTearDown(() => appLanguage.value = AppLanguage.de);

    await tester.pumpWidget(const MyApp());
    expect(find.text('Spiel starten'), findsOneWidget);
    expect(find.text('Teste dein Wissen über die deutsche Sprache'), findsOneWidget);

    appLanguage.value = AppLanguage.en;
    await tester.pump();

    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('Test your knowledge of the German language'), findsOneWidget);
    expect(find.text('Spiel starten'), findsNothing);
  });
}
