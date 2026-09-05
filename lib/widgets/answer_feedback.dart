import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firework_particle.dart';
import 'shake.dart';

/// Bündelt die Antwort-Feedback-Effekte aus ROADMAP_QuizApp.md Abschnitt 18e
/// (Konfetti, grünes Aufblitzen, Wackeln, Haptik), damit nicht jedes
/// Format-Screen dieselbe Logik dupliziert. Call [triggerCorrectFeedback]
/// bzw. [triggerWrongFeedback] NACH dem eigenen setState()-Block (nicht
/// darin), da triggerWrongFeedback selbst setState auslöst.
mixin AnswerFeedbackMixin<T extends StatefulWidget> on State<T> {
  late final ConfettiController _feedbackConfetti =
      ConfettiController(duration: const Duration(milliseconds: 900));
  int _feedbackShakeTrigger = 0;
  bool _feedbackShowFlash = false;

  void triggerCorrectFeedback() {
    HapticFeedback.heavyImpact();
    _feedbackConfetti.play();
    setState(() => _feedbackShowFlash = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _feedbackShowFlash = false);
    });
  }

  void triggerWrongFeedback() {
    HapticFeedback.mediumImpact();
    setState(() => _feedbackShakeTrigger++);
  }

  @override
  void dispose() {
    _feedbackConfetti.dispose();
    super.dispose();
  }

  Widget wrapWithShake(Widget child) => ShakeOnTrigger(trigger: _feedbackShakeTrigger, child: child);

  /// In einen [Stack] als letzte Kinder einfügen, damit sie über dem Inhalt liegen.
  List<Widget> feedbackOverlayLayers() {
    return [
      IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _feedbackShowFlash ? 1 : 0,
          child: Container(color: Colors.green.withValues(alpha: 0.25)),
        ),
      ),
      Align(
        alignment: const Alignment(0, -0.2),
        child: ConfettiWidget(
          confettiController: _feedbackConfetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 35,
          maxBlastForce: 30,
          minBlastForce: 12,
          gravity: 0.15,
          minimumSize: const Size(5, 5),
          maximumSize: const Size(11, 11),
          colors: fireworkColors,
          createParticlePath: drawFireworkSpark,
          shouldLoop: false,
        ),
      ),
    ];
  }
}
