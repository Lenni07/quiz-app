/// Übergibt "diese Runde gehört zu Match X, Index Y" an ResultScreen, ohne
/// die 16 Format-Bildschirme dafür anfassen zu müssen - sie kennen ihren
/// Kontext nicht und rufen ResultScreen ganz normal auf. Wird von der
/// Match-Orchestrierung (siehe career_match_screen.dart) direkt vor dem
/// Start einer Runde gesetzt und von ResultScreen einmalig "verbraucht".
/// Gleiches Muster wie GameModeContext.
class MatchRoundContext {
  static String? _matchId;
  static int? _roundIndex;

  static void set(String matchId, int roundIndex) {
    _matchId = matchId;
    _roundIndex = roundIndex;
  }

  static ({String matchId, int roundIndex})? consume() {
    final matchId = _matchId;
    final roundIndex = _roundIndex;
    if (matchId == null || roundIndex == null) return null;
    _matchId = null;
    _roundIndex = null;
    return (matchId: matchId, roundIndex: roundIndex);
  }
}
