// Einfacher Smoke-Test: Startbildschirm zeigt sich richtig an und
// "Spiel starten" führt zur Modus-Auswahl.
import 'package:flutter_test/flutter_test.dart';

import 'package:rank_up/main.dart';

void main() {
  testWidgets('Startbildschirm zeigt Titel und führt zur Modus-Auswahl', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Quiz Up Your Rank'), findsOneWidget);
    expect(find.text('Spiel starten'), findsOneWidget);

    await tester.tap(find.text('Spiel starten'));
    await tester.pumpAndSettle();

    expect(find.text('Modus wählen'), findsOneWidget);
  });
}
