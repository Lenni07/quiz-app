// Freischalt-Checkliste (siehe lib/widgets/unlock_steps.dart und
// ROADMAP_QuizApp.md Abschnitt 18h "Gestufter Zugang"). Offene Schritte
// müssen deutlich (rot) markiert sein, nicht nur als grauer Hinweistext.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/theme/app_theme.dart';
import 'package:rank_up/widgets/unlock_steps.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  bool hasRedText(WidgetTester tester, String partial) {
    final texts = tester.widgetList<RichText>(find.byType(RichText));
    for (final rt in texts) {
      final span = rt.text as TextSpan;
      final flat = span.toPlainText();
      if (!flat.contains(partial)) continue;
      // Irgendein Teil des Spans muss in Signalrot gesetzt sein.
      var red = false;
      span.visitChildren((child) {
        if (child is TextSpan && child.style?.color == AppColors.signalRed) red = true;
        return true;
      });
      if (span.style?.color == AppColors.signalRed) red = true;
      if (red) return true;
    }
    return false;
  }

  testWidgets('beide Schritte offen: Titel + beide Zeilen rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(googleDone: false, crewIdDone: false)));

    expect(find.text(S.t('unlock_todo_title')), findsOneWidget);
    expect(hasRedText(tester, S.t('unlock_step_google')), isTrue);
    expect(hasRedText(tester, S.t('unlock_step_crewid')), isTrue);
  });

  testWidgets('Google erledigt, Crew-ID offen: nur die Crew-ID-Zeile rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(googleDone: true, crewIdDone: false)));

    expect(hasRedText(tester, S.t('unlock_step_google')), isFalse);
    expect(hasRedText(tester, S.t('unlock_step_crewid')), isTrue);
  });

  testWidgets('alles erledigt: Erfolgstext, nichts rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(googleDone: true, crewIdDone: true)));

    expect(find.text(S.t('unlock_all_done')), findsOneWidget);
    expect(hasRedText(tester, S.t('unlock_step_crewid')), isFalse);
  });

  testWidgets('compact: rendert auch ohne feste Breite (zentriertes Sperr-Panel)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [UnlockSteps(googleDone: false, crewIdDone: false, compact: true)],
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text(S.t('unlock_todo_title')), findsNothing); // compact: kein Titel
  });
}
