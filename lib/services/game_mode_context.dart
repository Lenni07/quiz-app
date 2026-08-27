/// Merkt sich, über welchen Hauptbereich (siehe ROADMAP_QuizApp.md
/// Abschnitt 15) der Nutzer gerade ein Spielformat spielt. Wird beim
/// Betreten von Karrieremodus/Lernmodus gesetzt und von ResultScreen
/// gelesen, um zu entscheiden, ob eine Runde fürs Karriere-Matchmaking
/// eingereicht werden soll. Bewusst als simpler globaler Zustand statt
/// Parameter durch jeden der 15 Formate hindurchgereicht - passt zum
/// bisherigen Stil der App (kein Provider/Riverpod).
enum GameMode { career, learn, other }

class GameModeContext {
  static GameMode current = GameMode.other;
}
