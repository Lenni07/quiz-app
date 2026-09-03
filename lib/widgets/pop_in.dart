import 'package:flutter/material.dart';

/// Lässt sein Kind beim ersten Erscheinen sanft aufpoppen/einfliegen (Fade +
/// Skalierung + leichter Versatz von unten) statt abrupt dazustehen (siehe
/// ROADMAP_QuizApp.md Abschnitt 13b, zweite Optik-Runde). Spielt nur einmal
/// beim Mount, nicht bei jedem Rebuild - für einzeln erscheinende Panels
/// gedacht, nicht für Listen mit häufigen Stream-Updates.
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
