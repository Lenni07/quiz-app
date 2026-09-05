import 'package:audioplayers/audioplayers.dart';
import 'tone_generator.dart';

/// Kurze, synthetisch erzeugte Antwort-Töne (siehe ROADMAP_QuizApp.md
/// Abschnitt 18e) - kein Sound-Asset nötig, daher kein Lizenzrisiko. Fehler
/// (z. B. kein Audio-Ausgabegerät, Browser blockiert Autoplay) werden
/// bewusst verschluckt, damit ein fehlender Ton nie das Spiel unterbricht.
class SoundEffects {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();

  final AudioPlayer _player = AudioPlayer();

  late final BytesSource _correctTone = BytesSource(
    generateWavTone(frequencies: const [880, 1318.51]),
  );
  late final BytesSource _wrongTone = BytesSource(
    generateWavTone(frequencies: const [220], noteDuration: const Duration(milliseconds: 220)),
  );

  Future<void> playCorrect() async {
    try {
      await _player.play(_correctTone);
    } catch (_) {}
  }

  Future<void> playWrong() async {
    try {
      await _player.play(_wrongTone);
    } catch (_) {}
  }
}
