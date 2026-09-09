// E-Mail-Link-Anmeldung (siehe lib/services/auth_service.dart,
// lib/screens/complete_email_sign_in_screen.dart, ROADMAP_QuizApp.md
// Abschnitt 18h). Die echte Firebase-Anmeldung wird im Emulator getestet -
// hier die Adress-Auflösung und das Verhalten des Abschluss-Bildschirms.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rank_up/l10n/strings.dart';
import 'package:rank_up/screens/complete_email_sign_in_screen.dart';
import 'package:rank_up/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.outcomes, {this.email});
  final List<EmailLinkOutcome> outcomes;
  final String? email;
  final List<String?> calledWithEmail = [];
  int _i = 0;

  @override
  User? get currentUser => null; // -> Screen überspringt den Firestore-Schritt

  @override
  String? get linkedEmail => email;

  @override
  Future<EmailLinkOutcome> completeEmailLinkSignIn(String link, {String? email}) async {
    calledWithEmail.add(email);
    return outcomes[_i++ % outcomes.length];
  }
}

void main() {
  group('resolveEmailForLink', () {
    test('erneut eingegebene Adresse hat Vorrang', () {
      expect(resolveEmailForLink(override: 'new@x.de', stored: 'old@x.de'), 'new@x.de');
    });
    test('sonst die lokal gemerkte Adresse', () {
      expect(resolveEmailForLink(override: null, stored: 'old@x.de'), 'old@x.de');
      expect(resolveEmailForLink(override: '  ', stored: 'old@x.de'), 'old@x.de');
    });
    test('keine Adresse verfügbar -> null (anderes Gerät: nachfragen)', () {
      expect(resolveEmailForLink(override: null, stored: null), isNull);
      expect(resolveEmailForLink(override: '', stored: ''), isNull);
    });
  });

  group('CompleteEmailSignInScreen', () {
    Widget wrap(Widget child) => MaterialApp(home: child);

    testWidgets('gleiches Gerät: Anmeldung direkt erfolgreich', (tester) async {
      final fake = _FakeAuthService([EmailLinkOutcome.linkedAnonymous], email: 'sam@example.com');
      var done = 0;
      await tester.pumpWidget(wrap(CompleteEmailSignInScreen(
        link: 'https://x/?mode=signIn', onDone: () => done++, authService: fake,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('sam@example.com'), findsOneWidget);
      await tester.tap(find.text(S.t('email_link_continue')));
      expect(done, 1);
    });

    testWidgets('anderes Gerät: fragt nach der Adresse und schließt dann ab', (tester) async {
      final fake = _FakeAuthService(
        [EmailLinkOutcome.needsEmail, EmailLinkOutcome.signedInExisting],
        email: 'sam@example.com',
      );
      await tester.pumpWidget(wrap(CompleteEmailSignInScreen(
        link: 'https://x/?mode=signIn', onDone: () {}, authService: fake,
      )));
      await tester.pumpAndSettle();

      expect(find.text(S.t('email_link_needs_email')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sam@example.com');
      await tester.tap(find.text(S.t('email_link_finish')));
      await tester.pumpAndSettle();

      expect(fake.calledWithEmail.last, 'sam@example.com');
      expect(find.textContaining('sam@example.com'), findsWidgets);
    });

    testWidgets('ungültiger/abgelaufener Link: Hinweis + Weiter-Button', (tester) async {
      final fake = _FakeAuthService([EmailLinkOutcome.invalidLink]);
      await tester.pumpWidget(wrap(CompleteEmailSignInScreen(
        link: 'https://x/?mode=signIn', onDone: () {}, authService: fake,
      )));
      await tester.pumpAndSettle();

      expect(find.text(S.t('email_link_failed')), findsOneWidget);
      expect(find.text(S.t('email_link_continue')), findsOneWidget);
    });
  });
}
