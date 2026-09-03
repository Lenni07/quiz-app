import 'package:flutter/material.dart';

/// Begrenzt die App auf Handy-Proportionen, auch im breiten Desktop-Browser
/// (siehe ROADMAP_QuizApp.md Abschnitt 13b, zweite Optik-Runde) - wird
/// einmal über MaterialApp.builder um die gesamte App gelegt (Reiter-Leiste,
/// AppBar, alles), statt jeden Bildschirm einzeln anzupassen. Der Bereich
/// außerhalb der Handy-Breite bekommt eine ruhige, dunkle "Blende" statt des
/// nackten Browser-Weiß.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  static const double maxWidth = 480;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF04121C),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
