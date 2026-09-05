import 'package:audioplayers/audioplayers.dart';
import 'sound_settings.dart';

/// Kurze UI-/Antwort-Sounds (siehe ROADMAP_QuizApp.md Abschnitt 18e) - echte
/// Sound-Dateien aus Kenneys "Interface Sounds"-Paket (kenney.nl, CC0/
/// gemeinfrei, siehe assets/sounds/KENNEY_LICENSE.txt), lokal in
/// assets/sounds/ gebündelt statt zur Laufzeit nachgeladen, damit sie auch
/// offline funktionieren. Fehler (z. B. kein Audio-Ausgabegerät, Browser
/// blockiert Autoplay) werden bewusst verschluckt, damit ein fehlender Ton
/// nie das Spiel unterbricht. Jeder Sound bekommt einen eigenen
/// [AudioPlayer], damit sich schnell aufeinanderfolgende Sounds (z. B.
/// Klick direkt gefolgt von Antwort-Feedback) nicht gegenseitig abschneiden.
class SoundEffects {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _roundEndPlayer = AudioPlayer();

  Future<void> _play(AudioPlayer player, String assetPath) async {
    if (!soundEnabled.value) return;
    try {
      await player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> playCorrect() => _play(_correctPlayer, 'sounds/correct.ogg');
  Future<void> playWrong() => _play(_wrongPlayer, 'sounds/wrong.ogg');
  Future<void> playClick() => _play(_clickPlayer, 'sounds/click.ogg');
  Future<void> playRoundEnd() => _play(_roundEndPlayer, 'sounds/round_end.ogg');
}
