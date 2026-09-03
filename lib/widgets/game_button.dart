import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Plastischer, "drückbarer" Button (siehe ROADMAP_QuizApp.md Abschnitt
/// 13b): Verlauf + Schlagschatten + Glanzlicht-Fase oben, federt beim
/// Antippen leicht ein und wieder zurück. Für die wichtigsten
/// Haupt-Buttons gedacht (Spiel starten, Kampf starten, ...) - die vielen
/// übrigen Buttons in der App nutzen weiterhin den globalen ElevatedButton-
/// Stil aus app_theme.dart.
class GameButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Color foregroundColor;
  final double fontSize;

  const GameButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = AppColors.buttonGradient,
    this.foregroundColor = AppColors.deepSeaDark,
    this.fontSize = 18,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : AppColors.brass.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.35 : 0.1),
              width: 1.5,
            ),
            boxShadow: enabled && !_pressed
                ? const [
                    BoxShadow(color: Colors.black54, offset: Offset(0, 5), blurRadius: 8),
                    BoxShadow(color: Colors.white24, offset: Offset(0, -1), blurRadius: 0),
                  ]
                : enabled
                    ? const [BoxShadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3)]
                    : null,
          ),
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
      ),
    );
  }
}
