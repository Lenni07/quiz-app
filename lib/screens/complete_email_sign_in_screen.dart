import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/game_panel.dart';
import '../widgets/maritime_background.dart';

/// Schließt eine E-Mail-Link-Anmeldung ab (siehe ROADMAP_QuizApp.md
/// Abschnitt 18h). Wird angezeigt, wenn die App über einen Anmeldelink
/// geöffnet wurde. Deckt alle Fälle ab:
///  - Link auf demselben Gerät: Adresse ist gemerkt -> direkt fertig.
///  - Link auf anderem Gerät: Adresse fehlt -> Nutzer gibt sie erneut ein.
///  - Link abgelaufen / ungültig -> Hinweis + zurück in die App.
class CompleteEmailSignInScreen extends StatefulWidget {
  final String link;
  final VoidCallback onDone;
  final AuthService authService;

  CompleteEmailSignInScreen({
    super.key,
    required this.link,
    required this.onDone,
    AuthService? authService,
  }) : authService = authService ?? AuthService();

  @override
  State<CompleteEmailSignInScreen> createState() => _CompleteEmailSignInScreenState();
}

enum _Phase { working, needsEmail, success, failed }

class _CompleteEmailSignInScreenState extends State<CompleteEmailSignInScreen> {
  _Phase _phase = _Phase.working;
  final _emailController = TextEditingController();
  String? _signedInEmail;

  @override
  void initState() {
    super.initState();
    _attempt();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _attempt({String? email}) async {
    setState(() => _phase = _Phase.working);
    try {
      final outcome = await widget.authService.completeEmailLinkSignIn(widget.link, email: email);
      if (!mounted) return;
      switch (outcome) {
        case EmailLinkOutcome.needsEmail:
          setState(() => _phase = _Phase.needsEmail);
        case EmailLinkOutcome.invalidLink:
          setState(() => _phase = _Phase.failed);
        case EmailLinkOutcome.linkedAnonymous:
        case EmailLinkOutcome.signedIn:
        case EmailLinkOutcome.signedInExisting:
          final user = widget.authService.currentUser;
          if (user != null) {
            await UserProfileService().ensureProfileExists(user.uid);
          }
          if (!mounted) return;
          setState(() {
            _signedInEmail = widget.authService.linkedEmail;
            _phase = _Phase.success;
          });
      }
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaritimeBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: GamePanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(_icon, size: 44, color: AppColors.brassLight),
                  const SizedBox(height: 12),
                  Text(
                    S.t('email_link_title'),
                    textAlign: TextAlign.center,
                    style: displayStyle(fontSize: 20, color: AppColors.canvas),
                  ),
                  const SizedBox(height: 12),
                  ..._phaseBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (_phase) {
        _Phase.working => Icons.hourglass_top,
        _Phase.needsEmail => Icons.alternate_email,
        _Phase.success => Icons.check_circle,
        _Phase.failed => Icons.error_outline,
      };

  List<Widget> _phaseBody() {
    switch (_phase) {
      case _Phase.working:
        return const [Center(child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2)),
        ))];
      case _Phase.needsEmail:
        return [
          Text(
            S.t('email_link_needs_email'),
            style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(labelText: S.t('email_link_email_label')),
            onSubmitted: (v) => _attempt(email: v),
          ),
          const SizedBox(height: 12),
          GameButton(
            label: S.t('email_link_finish'),
            icon: Icons.login,
            fontSize: 15,
            onPressed: () => _attempt(email: _emailController.text),
          ),
        ];
      case _Phase.success:
        return [
          Text(
            _signedInEmail == null
                ? S.t('email_link_success')
                : S.f('email_link_success_as', [_signedInEmail!]),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 16),
          GameButton(
            label: S.t('email_link_continue'),
            icon: Icons.arrow_forward,
            fontSize: 15,
            onPressed: widget.onDone,
          ),
        ];
      case _Phase.failed:
        return [
          Text(
            S.t('email_link_failed'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 16),
          GameButton(
            label: S.t('email_link_continue'),
            icon: Icons.arrow_forward,
            fontSize: 15,
            onPressed: widget.onDone,
          ),
        ];
    }
  }
}
