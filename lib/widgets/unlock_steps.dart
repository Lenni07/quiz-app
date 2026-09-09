import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'game_panel.dart';

/// Zeigt die Schritte zum Freischalten der wettbewerbsrelevanten Bereiche
/// (Google-Anmeldung, Crew-ID, Nickname, Position - siehe ROADMAP_QuizApp.md
/// Abschnitt 18h). Noch offene Schritte werden rot hervorgehoben, bewusst
/// nicht nur als grauer Hinweistext. Wird im Profil und auf dem
/// Sperrbildschirm verwendet, damit die Anzeige an beiden Stellen gleich
/// aussieht.
class UnlockSteps extends StatelessWidget {
  final bool google;
  final bool crewId;
  final bool nickname;
  final bool position;

  /// Kompakte Variante ohne Panel/Titel - für den Sperrbildschirm, der schon
  /// ein eigenes Panel mitbringt.
  final bool compact;

  const UnlockSteps({
    super.key,
    required this.google,
    required this.crewId,
    required this.nickname,
    required this.position,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final steps = <(String, bool)>[
      (S.t('unlock_step_google'), google),
      (S.t('unlock_step_crewid'), crewId),
      (S.t('unlock_step_nickname'), nickname),
      (S.t('unlock_step_position'), position),
    ];
    final allDone = steps.every((s) => s.$2);

    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            allDone ? S.t('unlock_all_done') : S.t('unlock_todo_title'),
            style: TextStyle(
              color: allDone ? Colors.greenAccent.shade400 : AppColors.signalRed,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _StepRow(label: steps[i].$1, done: steps[i].$2),
        ],
      ],
    );

    if (compact) return rows;

    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      borderColor: allDone ? null : AppColors.signalRed,
      child: rows,
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;

  const _StepRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.greenAccent.shade400 : AppColors.signalRed;
    final suffix = done ? S.t('unlock_step_done') : S.t('unlock_step_open');
    // Text.rich statt Row+Expanded: bricht bei enger Breite um, funktioniert
    // aber auch ohne feste Breitenvorgabe (z. B. im zentrierten Sperr-Panel).
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: AppColors.canvas.withValues(alpha: done ? 0.75 : 1),
          fontSize: 13,
          fontWeight: done ? FontWeight.w400 : FontWeight.w700,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(done ? Icons.check_circle : Icons.cancel, size: 18, color: color),
            ),
          ),
          TextSpan(text: label),
          TextSpan(
            text: '  ·  $suffix',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
