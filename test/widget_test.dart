// Einfacher Smoke-Test: Startbildschirm mit "Spiel starten" führt zur
// Bereichs-Auswahl (Karriere/Lernmodus/Flottentreffen, siehe
// ROADMAP_QuizApp.md Abschnitt 15), von dort führt "Karrieremodus" zur
// Formatauswahl.
import 'package:flutter_test/flutter_test.dart';

import 'package:rank_up/main.dart';

void main() {
  testWidgets('Spiel starten führt zur Bereichs-Auswahl und Karrieremodus zur Formatauswahl',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Quiz Up Your Rank'), findsOneWidget);
    expect(find.text('Spiel starten'), findsOneWidget);

    await tester.tap(find.text('Spiel starten'));
    await tester.pumpAndSettle();

    expect(find.text('Karrieremodus'), findsOneWidget);
    expect(find.text('Lernmodus'), findsOneWidget);
    expect(find.text('Flottentreffen'), findsOneWidget);

    await tester.tap(find.text('Karrieremodus'));
    await tester.pumpAndSettle();

    expect(find.text('Allgemeinwissen-Quiz'), findsOneWidget);
  });
}
