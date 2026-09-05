import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Durchgängig maritimes Icon-Set (siehe ROADMAP_QuizApp.md Abschnitt 13b,
/// zweite Runde) - ersetzt generische/thematisch fremde Material-Icons
/// (z. B. die Karate-Figur für "1 vs 1", zufällige Avatare wie Pfote/
/// Rakete). Ein Teil nutzt bereits gut passende Material-Icons (Anker,
/// Segelboot, Wellen, Kompass), der Rest ist selbst per CustomPainter
/// gezeichnet - keine externen Icon-Pakete/Bild-Assets nötig.
enum MaritimeIconShape {
  anchor,
  sailboat,
  waves,
  compass,
  lighthouse,
  shipWheel,
  lifeRing,
  seagull,
  porthole,
  captainHat,
}

class MaritimeIcon extends StatelessWidget {
  final MaritimeIconShape shape;
  final double size;
  final Color color;

  const MaritimeIcon(this.shape, {super.key, this.size = 24, required this.color});

  static const Map<MaritimeIconShape, IconData> _materialIcons = {
    MaritimeIconShape.anchor: Icons.anchor,
    MaritimeIconShape.sailboat: Icons.sailing,
    MaritimeIconShape.waves: Icons.waves,
    MaritimeIconShape.compass: Icons.explore,
  };

  @override
  Widget build(BuildContext context) {
    final materialIcon = _materialIcons[shape];
    if (materialIcon != null) {
      return Icon(materialIcon, size: size, color: color);
    }
    return CustomPaint(
      size: Size(size, size),
      painter: _MaritimeIconPainter(shape: shape, color: color),
    );
  }
}

/// Zeichnet in einem normierten 24x24-Koordinatenraum, skaliert auf die
/// tatsächliche Größe - dieselbe Konvention wie Material Icons.
class _MaritimeIconPainter extends CustomPainter {
  final MaritimeIconShape shape;
  final Color color;

  _MaritimeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    switch (shape) {
      case MaritimeIconShape.lighthouse:
        _paintLighthouse(canvas);
      case MaritimeIconShape.shipWheel:
        _paintShipWheel(canvas);
      case MaritimeIconShape.lifeRing:
        _paintLifeRing(canvas);
      case MaritimeIconShape.seagull:
        _paintSeagull(canvas);
      case MaritimeIconShape.porthole:
        _paintPorthole(canvas);
      case MaritimeIconShape.captainHat:
        _paintCaptainHat(canvas);
      case MaritimeIconShape.anchor:
      case MaritimeIconShape.sailboat:
      case MaritimeIconShape.waves:
      case MaritimeIconShape.compass:
        break; // werden über Material-Icons gerendert, nicht hier.
    }

    canvas.restore();
  }

  /// Bewusst breiter und kontrastreicher als eine "echte" schlanke
  /// Leuchtturm-Silhouette (siehe ROADMAP_QuizApp.md Abschnitt 18e) - dünne
  /// Linien/Strahlen verschwinden bei kleiner Darstellung (z. B. in einer
  /// Statistik-Kachel), deshalb ein kräftiges Band statt zweier dünner
  /// Streifen und ein solider Lichtpunkt statt dünner Strahlen-Linien.
  void _paintLighthouse(Canvas canvas) {
    final fill = Paint()..color = color;
    final tower = Path()
      ..moveTo(6.5, 22.5)
      ..lineTo(17.5, 22.5)
      ..lineTo(15.5, 8)
      ..lineTo(8.5, 8)
      ..close();
    canvas.drawPath(tower, fill);

    final stripe = Paint()..color = const Color(0xFF071B29);
    canvas.drawRect(const Rect.fromLTRB(7.6, 12.5, 16.4, 16), stripe);

    canvas.drawRect(const Rect.fromLTRB(8, 3.5, 16, 8), fill);
    final cap = Path()
      ..moveTo(7, 3.5)
      ..lineTo(17, 3.5)
      ..lineTo(12, 1)
      ..close();
    canvas.drawPath(cap, fill);

    final glow = Paint()..color = const Color(0xFFFFE8A3);
    canvas.drawCircle(const Offset(12, 5.5), 2.3, glow);
  }

  void _paintShipWheel(Canvas canvas) {
    const center = Offset(12, 12);
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8.5, ring);

    final spoke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final knob = Paint()..color = color;
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final dx = center.dx + 8.5 * math.cos(angle);
      final dy = center.dy + 8.5 * math.sin(angle);
      final handleDx = center.dx + 10.5 * math.cos(angle);
      final handleDy = center.dy + 10.5 * math.sin(angle);
      canvas.drawLine(Offset(dx * 0.35 + center.dx * 0.65, dy * 0.35 + center.dy * 0.65), Offset(dx, dy), spoke);
      canvas.drawCircle(Offset(handleDx, handleDy), 1.4, knob);
    }
    canvas.drawCircle(center, 2.6, Paint()..color = color);
  }

  void _paintLifeRing(Canvas canvas) {
    const center = Offset(12, 12);
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, 7, ring);

    final tick = Paint()
      ..color = const Color(0xFF071B29)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(const Offset(12, 3.2), const Offset(12, 6.8), tick);
    canvas.drawLine(const Offset(12, 17.2), const Offset(12, 20.8), tick);
    canvas.drawLine(const Offset(3.2, 12), const Offset(6.8, 12), tick);
    canvas.drawLine(const Offset(17.2, 12), const Offset(20.8, 12), tick);
  }

  void _paintSeagull(Canvas canvas) {
    final wing = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(3, 15)
      ..quadraticBezierTo(8, 8, 12, 14)
      ..quadraticBezierTo(16, 8, 21, 15);
    canvas.drawPath(path, wing);
  }

  void _paintPorthole(Canvas canvas) {
    const center = Offset(12, 12);
    final rim = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(center, 8, rim);

    final glass = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 5.5, glass);

    final bolt = Paint()..color = color;
    for (final angle in [45, 135, 225, 315]) {
      final rad = angle * math.pi / 180;
      canvas.drawCircle(Offset(center.dx + 8 * math.cos(rad), center.dy + 8 * math.sin(rad)), 1, bolt);
    }
  }

  void _paintCaptainHat(Canvas canvas) {
    final fill = Paint()..color = color;
    final band = RRect.fromRectAndRadius(const Rect.fromLTRB(6, 8, 18, 14.5), const Radius.circular(2));
    canvas.drawRRect(band, fill);

    final brim = Path()
      ..moveTo(3, 15.5)
      ..quadraticBezierTo(12, 12.5, 21, 15.5)
      ..quadraticBezierTo(12, 18.5, 3, 15.5)
      ..close();
    canvas.drawPath(brim, fill);

    final emblem = Paint()..color = const Color(0xFF071B29);
    canvas.drawCircle(const Offset(12, 11), 1.6, emblem);
  }

  @override
  bool shouldRepaint(covariant _MaritimeIconPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
