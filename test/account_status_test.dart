// Prüft die Konto-Anzeige im Profil (siehe lib/widgets/account_status.dart
// und ROADMAP_QuizApp.md Abschnitt 18h). Die eigentliche Google-
// Verknüpfung läuft über Firebase Auth und wird im Emulator getestet -
// hier nur, dass die Anzeige je nach Kontostand das Richtige zeigt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/widgets/account_status.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('anonym: zeigt Hinweistext und Anmelde-Button', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(AccountStatus(
      isFullAccount: false,
      email: null,
      linking: false,
      canLink: true,
      onLink: () => tapped++,
    )));

    expect(find.text(S.t('account_link_google_button')), findsOneWidget);
    expect(find.textContaining('Gerät'), findsOneWidget);

    await tester.tap(find.text(S.t('account_link_google_button')));
    expect(tapped, 1);
  });

  testWidgets('während der Verknüpfung: Ladeanzeige statt Button', (tester) async {
    await tester.pumpWidget(wrap(AccountStatus(
      isFullAccount: false,
      email: null,
      linking: true,
      canLink: true,
      onLink: () {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(S.t('account_link_google_button')), findsNothing);
  });

  testWidgets('vollwertiges Konto: zeigt die verknüpfte E-Mail, keinen Button', (tester) async {
    await tester.pumpWidget(wrap(const AccountStatus(
      isFullAccount: true,
      email: 'crew.tester@example.com',
      linking: false,
      canLink: true,
      onLink: _noop,
    )));

    expect(find.textContaining('crew.tester@example.com'), findsOneWidget);
    expect(find.text(S.t('account_link_google_button')), findsNothing);
  });
}

void _noop() {}
