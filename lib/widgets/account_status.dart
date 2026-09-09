import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'game_button.dart';
import 'game_panel.dart';

/// Konto-Bereich im Profil (siehe ROADMAP_QuizApp.md Abschnitt 18h).
///
/// Anonym: Hinweis + zwei Wege zum vollwertigen Konto - Google-Popup oder
/// E-Mail-Link ohne Passwort (für Nutzer ohne Google-Konto, v. a. iPhone).
/// Angemeldet: verknüpfte Adresse + "Abmelden / Konto wechseln".
///
/// Ist [canLink] false (Nicht-Web-Plattformen, wo beide Wege noch nicht
/// verfügbar sind), erscheint stattdessen ein kurzer Hinweis.
class AccountStatus extends StatefulWidget {
  final bool isFullAccount;
  final String? email;
  final bool canLink;

  final bool linkingGoogle;
  final VoidCallback onLinkGoogle;

  final bool sendingEmailLink;

  /// Adresse, an die zuletzt ein Link ging (`null` = noch keiner) - zeigt den
  /// "Postfach prüfen"-Hinweis.
  final String? emailLinkSentTo;
  final ValueChanged<String> onSendEmailLink;

  final bool signingOut;
  final VoidCallback onSignOut;

  const AccountStatus({
    super.key,
    required this.isFullAccount,
    required this.email,
    required this.canLink,
    required this.linkingGoogle,
    required this.onLinkGoogle,
    required this.sendingEmailLink,
    required this.emailLinkSentTo,
    required this.onSendEmailLink,
    required this.signingOut,
    required this.onSignOut,
  });

  @override
  State<AccountStatus> createState() => _AccountStatusState();
}

class _AccountStatusState extends State<AccountStatus> {
  final _emailController = TextEditingController();
  bool _emailFormOpen = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullAccount) return _signedInPanel();
    return _anonymousPanel();
  }

  Widget _signedInPanel() {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.greenAccent.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.f('account_linked_as', [widget.email ?? '']),
                  style: const TextStyle(color: AppColors.canvas),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.signingOut)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(S.t('account_sign_out_button')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _anonymousPanel() {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t('account_anonymous_info'),
            style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (!widget.canLink)
            Text(
              S.t('account_link_web_only'),
              style: TextStyle(color: AppColors.brassLight, fontSize: 12, fontStyle: FontStyle.italic),
            )
          else ...[
            if (widget.linkingGoogle)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else
              GameButton(
                label: S.t('account_link_google_button'),
                icon: Icons.login,
                fontSize: 15,
                onPressed: widget.onLinkGoogle,
              ),
            const SizedBox(height: 10),
            _emailLinkSection(),
          ],
        ],
      ),
    );
  }

  Widget _emailLinkSection() {
    if (widget.emailLinkSentTo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.brassLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.f('account_email_link_sent', [widget.emailLinkSentTo!]),
                  style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.85), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.sendingEmailLink ? null : () => widget.onSendEmailLink(widget.emailLinkSentTo!),
              child: Text(S.t('account_email_link_resend')),
            ),
          ),
        ],
      );
    }

    if (!_emailFormOpen) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _emailFormOpen = true),
          icon: const Icon(Icons.alternate_email, size: 18),
          label: Text(S.t('account_link_email_button')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: S.t('email_link_email_label'),
            helperText: S.t('account_email_link_helper'),
          ),
          onSubmitted: (v) => widget.onSendEmailLink(v),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: widget.sendingEmailLink
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton.icon(
                  onPressed: () => widget.onSendEmailLink(_emailController.text),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(S.t('account_email_link_send')),
                ),
        ),
      ],
    );
  }
}
