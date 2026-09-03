import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Plastisches Panel/Karte mit Verlauf, Schlagschatten und einer feinen
/// Glanzlicht-Fase oben (siehe ROADMAP_QuizApp.md Abschnitt 13b) - Ersatz
/// für flache, einfarbige Container an prominenten Stellen.
class GamePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;

  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.borderColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.panelGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.brass.withValues(alpha: 0.35), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 14),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
        ),
        child: child,
      ),
    );
  }
}
