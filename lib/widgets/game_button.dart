import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Plastischer, "drückbarer" Button (siehe ROADMAP_QuizApp.md Abschnitt
/// 13b): Verlauf + Schlagschatten + Glanzlicht-Fase oben/Innenschatten
/// unten, federt beim Antippen spürbar ein und wieder zurück. Optional ein
/// dezentes Dauer-Pulsieren für die wichtigste Aktion auf einem Bildschirm
/// (siehe [pulse]). Für die wichtigsten Haupt-Buttons gedacht (Spiel
/// starten, Quiz-Duell starten, ...) - die vielen übrigen Buttons in der App
/// nutzen weiterhin den globalen ElevatedButton-Stil aus app_theme.dart.
class GameButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Color foregroundColor;
  final double fontSize;
  final bool pulse;

  const GameButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = AppColors.buttonGradient,
    this.foregroundColor = AppColors.deepSeaDark,
    this.fontSize = 18,
    this.pulse = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(16);

    Widget button = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: Duration(milliseconds: _pressed ? 90 : 220),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : AppColors.brass.withValues(alpha: 0.3),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.35 : 0.1), width: 1.5),
            boxShadow: enabled && !_pressed
                ? const [BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 8)]
                : enabled
                    ? const [BoxShadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: enabled ? widget.foregroundColor : widget.foregroundColor.withValues(alpha: 0.5)),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: displayStyle(
                          fontSize: widget.fontSize,
                          color: enabled ? widget.foregroundColor : widget.foregroundColor.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 12,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (enabled)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 8,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final pulseController = _pulseController;
    if (pulseController == null) return button;
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final glow = 0.15 + 0.15 * pulseController.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [BoxShadow(color: AppColors.brassLight.withValues(alpha: glow), blurRadius: 16, spreadRadius: 2)],
          ),
          child: child,
        );
      },
      child: button,
    );
  }
}
