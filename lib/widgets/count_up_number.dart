import 'package:flutter/material.dart';

/// Zahl, die beim Erscheinen bzw. bei jeder Änderung vom zuletzt gezeigten
/// zum neuen Wert hochzählt (siehe ROADMAP_QuizApp.md Abschnitt 13b, zweite
/// Optik-Runde) - animiert bewusst nur die Differenz, nicht immer wieder ab
/// 0, damit ein Stream-Update (z. B. Live-Wertung) nicht bei jeder
/// Kleinigkeit neu von vorne zählt.
class CountUpNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String Function(int)? format;

  const CountUpNumber(this.value, {super.key, this.style, this.format});

  @override
  State<CountUpNumber> createState() => _CountUpNumberState();
}

class _CountUpNumberState extends State<CountUpNumber> {
  late int _previous = widget.value;

  @override
  Widget build(BuildContext context) {
    final tween = IntTween(begin: _previous, end: widget.value);
    _previous = widget.value;
    return TweenAnimationBuilder<int>(
      tween: tween,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(widget.format?.call(value) ?? '$value', style: widget.style),
    );
  }
}
