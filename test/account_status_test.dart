// Prüft die Konto-Anzeige im Profil (siehe lib/widgets/account_status.dart
// und ROADMAP_QuizApp.md Abschnitt 18h). Die eigentliche Anmeldung läuft
// über Firebase Auth und wird im Emulator getestet - hier nur, dass die
// Anzeige je nach Kontostand das Richtige zeigt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/widgets/account_status.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  AccountStatus build({
    required bool isFullAccount,
    String? email,
    bool canLink = true,
    bool linkingGoogle = false,
    bool sendingEmailLink = false,
    String? emailLinkSentTo,
    bool signingOut = false,
    void Function(String)? onSendEmailLink,
    VoidCallback? onSignOut,
    VoidCallback? onLinkGoogle,
  }) {
    return AccountStatus(
      isFullAccount: isFullAccount,
      email: email,
      canLink: canLink,
      linkingGoogle: linkingGoogle,
      onLinkGoogle: onLinkGoogle ?? () {},
      sendingEmailLink: sendingEmailLink,
      emailLinkSentTo: emailLinkSentTo,
      onSendEmailLink: onSendEmailLink ?? (_) {},
      signingOut: signingOut,
      onSignOut: onSignOut ?? () {},
    );
  }

  testWidgets('anonym: Google-Button und E-Mail-Link-Option', (tester) async {
    await tester.pumpWidget(wrap(build(isFullAccount: false)));

    expect(find.text(S.t('account_link_google_button')), findsOneWidget);
    expect(find.text(S.t('account_link_email_button')), findsOneWidget);
  });

  testWidgets('anonym: E-Mail-Link-Option öffnet ein Adressfeld und sendet', (tester) async {
    String? sentTo;
    await tester.pumpWidget(wrap(build(
      isFullAccount: false,
      onSendEmailLink: (v) => sentTo = v,
    )));

    await tester.tap(find.text(S.t('account_link_email_button')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'sailor@example.com');
    await tester.tap(find.text(S.t('account_email_link_send')));
    expect(sentTo, 'sailor@example.com');
  });

  testWidgets('Link gesendet: Postfach-Hinweis mit Adresse statt Formular', (tester) async {
    await tester.pumpWidget(wrap(build(
      isFullAccount: false,
      emailLinkSentTo: 'sailor@example.com',
    )));

    expect(find.textContaining('sailor@example.com'), findsOneWidget);
    expect(find.text(S.t('account_email_link_send')), findsNothing);
    expect(find.text(S.t('account_email_link_resend')), findsOneWidget);
  });

  testWidgets('angemeldet: zeigt E-Mail und einen Abmelde-Button, keine Anmelde-Buttons', (tester) async {
    var signedOut = 0;
    await tester.pumpWidget(wrap(build(
      isFullAccount: true,
      email: 'crew.tester@example.com',
      onSignOut: () => signedOut++,
    )));

    expect(find.textContaining('crew.tester@example.com'), findsOneWidget);
    expect(find.text(S.t('account_link_google_button')), findsNothing);
    expect(find.text(S.t('account_link_email_button')), findsNothing);

    await tester.tap(find.text(S.t('account_sign_out_button')));
    expect(signedOut, 1);
  });

  testWidgets('Nicht-Web: Hinweis statt Anmelde-Optionen', (tester) async {
    await tester.pumpWidget(wrap(build(isFullAccount: false, canLink: false)));

    expect(find.text(S.t('account_link_web_only')), findsOneWidget);
    expect(find.text(S.t('account_link_google_button')), findsNothing);
  });
}
