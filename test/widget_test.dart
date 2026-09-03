// Einfacher Smoke-Test: Startbildschirm mit "Spiel starten" führt zur
// Reiter-Navigation (siehe ROADMAP_QuizApp.md Abschnitt 16) mit den 5
// Hauptbereichen.
import 'package:flutter_test/flutter_test.dart';

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

    // Standardmäßig ist der 1-vs-1-Reiter aktiv (Hauptmodus).
    expect(find.text('Kampf starten'), findsOneWidget);

    await tester.tap(find.text('Lernmodus'));
    await tester.pumpAndSettle();

    expect(find.text('Allgemeinwissen-Quiz'), findsOneWidget);
  });
}
