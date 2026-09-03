import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Programmatisch gezeichnete maritime Ornamente (siehe ROADMAP_QuizApp.md
/// Abschnitt 13b) - Wellen und ein Tau als Trenner/Dekoration, ganz ohne
/// externe Bild-Assets.

class _WavePainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double waveLength;

  _WavePainter({required this.color, required this.waveHeight, required this.waveLength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, size.height);
    var x = 0.0;
    var up = true;
    while (x < size.width) {
      final nextX = math.min(x + waveLength / 2, size.width);
      path.quadraticBezierTo(
        x + (nextX - x) / 2,
        up ? size.height - waveHeight : size.height + waveHeight,
        nextX,
        size.height,
      );
      x = nextX;
      up = !up;
    }
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.waveHeight != waveHeight || oldDelegate.waveLength != waveLength;
}

/// Wellenband als Trenner/Dekoration zwischen zwei Bereichen.
class WaveDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double waveLength;

  const WaveDivider({super.key, this.height = 18, this.color = AppColors.deepSea, this.waveLength = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(color: color, waveHeight: height * 0.55, waveLength: waveLength),
        size: Size.infinite,
      ),
    );
  }
}

class _RopePainter extends CustomPainter {
  final Color color;

  _RopePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strand = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const period = 14.0;
    final midY = size.height / 2;
    final amplitude = size.height / 2 - 1;

    for (final phase in [0.0, period / 2]) {
      final path = Path();
      var x = -period;
      var first = true;
      while (x < size.width + period) {
        final y = midY + amplitude * math.sin((x + phase) / period * math.pi);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
        x += 2;
      }
      canvas.drawPath(path, strand);
    }
  }

  @override
  bool shouldRepaint(covariant _RopePainter oldDelegate) => oldDelegate.color != color;
}

/// Gedrehtes Tau als horizontaler Trenner - dezentes maritimes Detail
/// zwischen Abschnitten, z. B. in Listen oder unter Überschriften.
class RopeDivider extends StatelessWidget {
  final double height;
  final Color color;

  const RopeDivider({super.key, this.height = 10, this.color = AppColors.brass});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _RopePainter(color: color), size: Size.infinite),
    );
  }
}
