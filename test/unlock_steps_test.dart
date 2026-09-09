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
      if (!span.toPlainText().contains(partial)) continue;
      var red = span.style?.color == AppColors.signalRed;
      span.visitChildren((child) {
        if (child is TextSpan && child.style?.color == AppColors.signalRed) red = true;
        return true;
      });
      if (red) return true;
    }
    return false;
  }

  testWidgets('alles offen: Titel + alle vier Zeilen rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(
      google: false,
      crewId: false,
      nickname: false,
      position: false,
    )));

    expect(find.text(S.t('unlock_todo_title')), findsOneWidget);
    expect(hasRedText(tester, S.t('unlock_step_google')), isTrue);
    expect(hasRedText(tester, S.t('unlock_step_crewid')), isTrue);
    expect(hasRedText(tester, S.t('unlock_step_nickname')), isTrue);
    expect(hasRedText(tester, S.t('unlock_step_position')), isTrue);
  });

  testWidgets('nur Position offen: nur diese Zeile rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(
      google: true,
      crewId: true,
      nickname: true,
      position: false,
    )));

    expect(hasRedText(tester, S.t('unlock_step_google')), isFalse);
    expect(hasRedText(tester, S.t('unlock_step_nickname')), isFalse);
    expect(hasRedText(tester, S.t('unlock_step_position')), isTrue);
  });

  testWidgets('alles erledigt: Erfolgstext, nichts rot', (tester) async {
    await tester.pumpWidget(wrap(const UnlockSteps(
      google: true,
      crewId: true,
      nickname: true,
      position: true,
    )));

    expect(find.text(S.t('unlock_all_done')), findsOneWidget);
    expect(hasRedText(tester, S.t('unlock_step_position')), isFalse);
  });

  testWidgets('compact: rendert auch ohne feste Breite (zentriertes Sperr-Panel)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              UnlockSteps(
                google: false,
                crewId: false,
                nickname: false,
                position: false,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text(S.t('unlock_todo_title')), findsNothing); // compact: kein Titel
  });
}
