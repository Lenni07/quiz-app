import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Verlaufs-Hintergrund (heller oben, dunkler unten) mit einer dezenten,
/// programmatisch gezeichneten Wellentextur (siehe ROADMAP_QuizApp.md
/// Abschnitt 13b, zweite Optik-Runde) - ersetzt die bisherige flache,
/// einfarbige Fläche hinter den Panels. Als `body`-Hülle gedacht, nicht als
/// `scaffoldBackgroundColor` - so bleibt jeder Bildschirm frei, eigene
/// Inhalte darüber zu legen.
class MaritimeBackground extends StatelessWidget {
  final Widget child;

  const MaritimeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.deepSeaLight, AppColors.deepSea, AppColors.deepSeaDark],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _TexturePainter())),
        child,
      ],
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const lineSpacing = 34.0;
    const waveLength = 90.0;
    const waveHeight = 7.0;

    for (var y = -waveHeight; y < size.height + waveHeight; y += lineSpacing) {
      final path = Path();
      var x = 0.0;
      var first = true;
      while (x <= size.width) {
        final dy = y + waveHeight * math.sin(x / waveLength * 2 * math.pi);
        if (first) {
          path.moveTo(x, dy);
          first = false;
        } else {
          path.lineTo(x, dy);
        }
        x += 4;
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TexturePainter oldDelegate) => false;
}
