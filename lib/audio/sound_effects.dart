import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'sound_settings.dart';

const _correctAsset = 'sounds/correct.ogg';
const _wrongAsset = 'sounds/wrong.ogg';
const _clickAsset = 'sounds/click.ogg';
const _roundEndAsset = 'sounds/round_end.ogg';

/// Kurze UI-/Antwort-Sounds (siehe ROADMAP_QuizApp.md Abschnitt 18e) - echte
/// Sound-Dateien aus Kenneys "Interface Sounds"-Paket (kenney.nl, CC0/
/// gemeinfrei, siehe assets/sounds/KENNEY_LICENSE.txt), lokal in
/// assets/sounds/ gebündelt statt zur Laufzeit nachgeladen, damit sie auch
/// offline funktionieren. Jeder Sound bekommt einen eigenen [AudioPlayer],
/// damit sich schnell aufeinanderfolgende Sounds (z. B. Klick direkt
/// gefolgt von Antwort-Feedback) nicht gegenseitig abschneiden.
///
/// Fehler beim eigentlichen Abspielen werden weiterhin nicht dem Aufrufer
/// gemeldet (ein fehlender Ton darf nie das Spiel unterbrechen), aber jetzt
/// per [debugPrint] geloggt (in der Browser-DevTools-Konsole sichtbar) statt
/// komplett stumm verschluckt - sonst lässt sich "kein Ton" nicht von
/// "Ton spielt, nur nicht hörbar" unterscheiden.
class SoundEffects {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _roundEndPlayer = AudioPlayer();

  bool _preloaded = false;

  /// Lädt alle vier Sound-Dateien einmalig vorab (setzt nur die Quelle,
  /// spielt nichts ab - löst also keine Autoplay-Sperre aus). Wichtig für
  /// Web: ohne Vorladen holt der allererste `play()`-Aufruf die Datei erst
  /// per HTTP-Request, und dieser zusätzliche Netzwerk-Umweg kann dazu
  /// führen, dass der Browser den eigentlichen Wiedergabestart nicht mehr
  /// als direkte Folge der Nutzer-Interaktion erkennt und deshalb blockiert.
  /// Sicher mehrfach aufrufbar (z. B. beim App-Start) - läuft nur einmal.
  Future<void> preload() async {
    if (_preloaded) return;
    _preloaded = true;
    try {
      await Future.wait([
        _correctPlayer.setSource(AssetSource(_correctAsset)),
        _wrongPlayer.setSource(AssetSource(_wrongAsset)),
        _clickPlayer.setSource(AssetSource(_clickAsset)),
        _roundEndPlayer.setSource(AssetSource(_roundEndAsset)),
      ]);
      debugPrint('SoundEffects: alle vier Sounds erfolgreich vorgeladen');
    } catch (e) {
      debugPrint('SoundEffects: Vorladen fehlgeschlagen - $e');
      _preloaded = false; // nächster Aufruf (z. B. nach erster Interaktion) darf es erneut versuchen
    }
  }

  Future<void> _play(AudioPlayer player, String assetPath, String label) async {
    if (!soundEnabled.value) return;
    try {
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SoundEffects: Wiedergabe von "$label" fehlgeschlagen - $e');
    }
  }

  Future<void> playCorrect() => _play(_correctPlayer, _correctAsset, 'correct');
  Future<void> playWrong() => _play(_wrongPlayer, _wrongAsset, 'wrong');
  Future<void> playClick() => _play(_clickPlayer, _clickAsset, 'click');
  Future<void> playRoundEnd() => _play(_roundEndPlayer, _roundEndAsset, 'round_end');
}
