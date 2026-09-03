import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gestaltete Leerzustände statt einer einzelnen, mickrigen Textzeile
/// (siehe ROADMAP_QuizApp.md Abschnitt 13b, zweite Optik-Runde) - Icon plus
/// kurze, motivierende Zeile.
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String message;

  const EmptyState({super.key, this.icon, this.iconWidget, required this.message}) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, size: 44, color: AppColors.brass.withValues(alpha: 0.55)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.canvas.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
