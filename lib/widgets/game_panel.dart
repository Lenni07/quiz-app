import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Plastisches Panel/Karte mit Verlauf, Schlagschatten und simulierter
/// Innenschattierung (siehe ROADMAP_QuizApp.md Abschnitt 13b, zweite
/// Optik-Runde: mehr Plastizität, Lichtkante oben/dunklere Kante unten) -
/// Flutter kennt keine echten CSS-artigen "inset"-Schatten, deshalb wird der
/// Effekt über zwei dünne Verlaufsstreifen am oberen/unteren Innenrand
/// nachgebildet.
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
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.panelGradient,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.brass.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, offset: Offset(0, 7), blurRadius: 16),
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 14,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 10,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.22), Colors.black.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
