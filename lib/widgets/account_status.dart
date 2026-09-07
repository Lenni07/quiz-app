import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'game_button.dart';
import 'game_panel.dart';

/// Konto-Bereich im Profil (siehe ROADMAP_QuizApp.md Abschnitt 18h): zeigt
/// entweder "mit Google angemeldet" oder einen Hinweis + Button zum
/// Verknüpfen des anonymen Kontos. Ist [canLink] false (z. B. auf
/// Nicht-Web-Plattformen, wo die Google-Anmeldung noch nicht verfügbar
/// ist), erscheint stattdessen ein kurzer Hinweis.
class AccountStatus extends StatelessWidget {
  final bool isFullAccount;
  final String? email;
  final bool linking;
  final bool canLink;
  final VoidCallback onLink;

  const AccountStatus({
    super.key,
    required this.isFullAccount,
    required this.email,
    required this.linking,
    required this.canLink,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullAccount) {
      return GamePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 14,
        child: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.greenAccent.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                S.f('account_linked_as', [email ?? '']),
                style: const TextStyle(color: AppColors.canvas),
              ),
            ),
          ],
        ),
      );
    }

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
          if (!canLink)
            Text(
              S.t('account_link_web_only'),
              style: TextStyle(color: AppColors.brassLight, fontSize: 12, fontStyle: FontStyle.italic),
            )
          else if (linking)
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
              onPressed: onLink,
            ),
        ],
      ),
    );
  }
}
