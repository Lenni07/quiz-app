// Der Konto-Löschdialog (DSGVO, siehe ROADMAP_QuizApp.md Abschnitt 18i):
// "Endgültig löschen" bleibt gesperrt, bis das Bestätigungswort exakt (bis
// auf Groß-/Kleinschreibung und Rand-Leerzeichen) eingetippt ist.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/widgets/delete_account_dialog.dart';

void main() {
  // Öffnet den Dialog und legt das Ergebnis in [holder] ab (via .then, damit
  // es keinen "guarded function"-Konflikt mit weiteren pump-Aufrufen gibt).
  Future<void> openDialog(WidgetTester tester, List<bool?> holder) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => const DeleteAccountDialog(),
            ).then((v) => holder.add(v)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder confirmBtn() => find.widgetWithText(TextButton, S.t('delete_account_confirm'));

  testWidgets('Bestätigungsknopf ist ohne Eingabe gesperrt', (tester) async {
    await openDialog(tester, []);
    expect(tester.widget<TextButton>(confirmBtn()).onPressed, isNull);
  });

  testWidgets('falsches Wort lässt den Knopf gesperrt', (tester) async {
    await openDialog(tester, []);
    await tester.enterText(find.byType(TextField), 'irgendwas');
    await tester.pump();
    expect(tester.widget<TextButton>(confirmBtn()).onPressed, isNull);
  });

  testWidgets('korrektes Wort (klein/mit Leerzeichen) gibt den Knopf frei und bestätigt', (tester) async {
    final holder = <bool?>[];
    await openDialog(tester, holder);
    await tester.enterText(find.byType(TextField), '  ${S.t('delete_account_keyword').toLowerCase()} ');
    await tester.pump();
    expect(tester.widget<TextButton>(confirmBtn()).onPressed, isNotNull);

    await tester.tap(confirmBtn());
    await tester.pumpAndSettle();
    expect(holder.single, isTrue);
  });

  testWidgets('Abbrechen gibt false zurück', (tester) async {
    final holder = <bool?>[];
    await openDialog(tester, holder);
    await tester.tap(find.widgetWithText(TextButton, S.t('delete_account_cancel')));
    await tester.pumpAndSettle();
    expect(holder.single, isFalse);
  });
}
