// Einfacher Smoke-Test: Startbildschirm zeigt die drei gleichrangigen
// Hauptbereiche (siehe ROADMAP_QuizApp.md Abschnitt 15), und
// "Karrieremodus" führt zur Formatauswahl.
import 'package:flutter_test/flutter_test.dart';

import 'package:rank_up/main.dart';

void main() {
  testWidgets('Startbildschirm zeigt die drei Hauptbereiche und Karrieremodus führt zur Formatauswahl',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Quiz Up Your Rank'), findsOneWidget);
    expect(find.text('Karrieremodus'), findsOneWidget);
    expect(find.text('Lernmodus'), findsOneWidget);
    expect(find.text('Flottentreffen'), findsOneWidget);

    await tester.tap(find.text('Karrieremodus'));
    await tester.pumpAndSettle();

    expect(find.text('Karrieremodus'), findsWidgets);
    expect(find.text('Allgemeinwissen-Quiz'), findsOneWidget);
  });
}
